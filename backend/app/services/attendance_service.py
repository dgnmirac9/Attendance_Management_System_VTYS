"""
Attendance Service

Bu servis yoklama (attendance) işlemlerini yönetir:
- Attendance session oluşturma ve yönetimi
- Face-based check-in işlemleri
- Attendance kayıtları ve raporları
- Yoklama istatistikleri
"""

from datetime import datetime, timedelta
from typing import List, Optional, Dict, Any
from sqlalchemy.orm import Session
from sqlalchemy import and_, func, desc

from app.models.attendance import Attendance, AttendanceRecord
from app.models.course import Course, CourseEnrollment
from app.models.user import Student
from app.services.face_service import FaceService
from app.core.exceptions import (
    AttendanceNotFoundError,
    AttendanceSessionClosedError,
    StudentNotEnrolledError,
    DuplicateAttendanceError,
    FaceVerificationError
)


class AttendanceService:
    """Attendance işlemlerini yöneten servis sınıfı"""
    
    def __init__(self, db: Session):
        self.db = db
        self.face_service = FaceService()
    
    # ==================== ATTENDANCE SESSION MANAGEMENT ====================
    
    def create_attendance_session(
        self,
        course_id: int,
        instructor_id: int,
        session_name: str,
        description: Optional[str] = None,
        duration_minutes: int = 15
    ) -> Attendance:
        """
        Yeni bir yoklama oturumu oluşturur
        
        Args:
            course_id: Ders ID'si
            instructor_id: Eğitmen ID'si
            session_name: Oturum adı
            description: Oturum açıklaması
            duration_minutes: Oturum süresi (dakika)
            
        Returns:
            Attendance: Oluşturulan yoklama oturumu
            
        Raises:
            CourseNotFoundError: Ders bulunamadığında
            UnauthorizedError: Eğitmen yetkisi yoksa
        """
        # Dersin varlığını ve eğitmen yetkisini kontrol et
        course = self.db.query(Course).filter(
            and_(
                Course.course_id == course_id,
                Course.instructor_id == instructor_id,
                Course.is_active == True
            )
        ).first()
        
        if not course:
            raise AttendanceNotFoundError("Course not found or unauthorized")
        
        # Yoklama oturumu oluştur
        end_time = datetime.utcnow() + timedelta(minutes=duration_minutes)
        
        attendance = Attendance(
            course_id=course_id,
            instructor_id=instructor_id,  # Database still expects this field
            session_name=session_name,
            description=description,
            start_time=datetime.utcnow(),
            end_time=end_time,
            is_active=True
        )
        
        self.db.add(attendance)
        self.db.commit()
        self.db.refresh(attendance)
        
        return attendance
    
    def get_attendance_session(self, attendance_id: int) -> Optional[Attendance]:
        """
        Yoklama oturumunu ID ile getirir
        
        Args:
            attendance_id: Yoklama oturum ID'si
            
        Returns:
            Optional[Attendance]: Yoklama oturumu veya None
        """
        return self.db.query(Attendance).filter(
            Attendance.attendance_id == attendance_id
        ).first()
    
    def close_attendance_session(self, attendance_id: int, instructor_id: int) -> Attendance:
        """
        Yoklama oturumunu kapatır
        
        Args:
            attendance_id: Yoklama oturum ID'si
            instructor_id: Eğitmen ID'si
            
        Returns:
            Attendance: Kapatılan yoklama oturumu
            
        Raises:
            AttendanceNotFoundError: Oturum bulunamadığında
            UnauthorizedError: Eğitmen yetkisi yoksa
        """
        attendance = self.db.query(Attendance).join(Course).filter(
            and_(
                Attendance.attendance_id == attendance_id,
                Course.instructor_id == instructor_id,
                Attendance.is_active == True
            )
        ).first()
        
        if not attendance:
            raise AttendanceNotFoundError("Attendance session not found or unauthorized")
        
        # Oturumu kapat
        attendance.is_active = False
        attendance.end_time = datetime.utcnow()
        
        self.db.commit()
        self.db.refresh(attendance)
        
        return attendance
    
    def get_active_sessions_for_course(self, course_id: int) -> List[Attendance]:
        """
        Bir ders için aktif yoklama oturumlarını getirir
        
        Args:
            course_id: Ders ID'si
            
        Returns:
            List[Attendance]: Aktif yoklama oturumları
        """
        return self.db.query(Attendance).filter(
            and_(
                Attendance.course_id == course_id,
                Attendance.is_active == True,
                Attendance.end_time > datetime.utcnow()
            )
        ).order_by(desc(Attendance.start_time)).all()
    
    # ==================== FACE-BASED CHECK-IN ====================
    
    def check_in_with_face(
        self,
        attendance_id: int,
        student_id: int,
        face_image_data: bytes
    ) -> Dict[str, Any]:
        """
        Yüz tanıma ile yoklama alır
        
        Args:
            attendance_id: Yoklama oturum ID'si
            student_id: Öğrenci ID'si
            face_image_data: Yüz görüntüsü verisi
            
        Returns:
            Dict: Check-in sonucu ve detayları
            
        Raises:
            AttendanceNotFoundError: Oturum bulunamadığında
            AttendanceSessionClosedError: Oturum kapalıysa
            StudentNotEnrolledError: Öğrenci kayıtlı değilse
            DuplicateAttendanceError: Zaten yoklama alınmışsa
            FaceVerificationError: Yüz doğrulama başarısızsa
        """
        # Yoklama oturumunu kontrol et
        attendance = self.get_attendance_session(attendance_id)
        if not attendance:
            raise AttendanceNotFoundError("Attendance session not found")
        
        # Oturum aktif mi kontrol et
        current_time = datetime.utcnow()
        if not attendance.is_active or current_time > attendance.end_time:
            raise AttendanceSessionClosedError("Attendance session is closed")
        
        # Öğrencinin derse kayıtlı olup olmadığını kontrol et
        enrollment = self.db.query(CourseEnrollment).filter(
            and_(
                CourseEnrollment.course_id == attendance.course_id,
                CourseEnrollment.student_id == student_id,
                CourseEnrollment.enrollment_status == "active"
            )
        ).first()
        
        if not enrollment:
            raise StudentNotEnrolledError("Student is not enrolled in this course")
        
        # Daha önce yoklama alınmış mı kontrol et
        existing_record = self.db.query(AttendanceRecord).filter(
            and_(
                AttendanceRecord.attendance_id == attendance_id,
                AttendanceRecord.student_id == student_id
            )
        ).first()
        
        if existing_record:
            raise DuplicateAttendanceError("Attendance already recorded for this student")
        
        # Yüz doğrulama yap
        try:
            verification_result = self.face_service.verify_face(student_id, face_image_data)
            
            if not verification_result["is_verified"]:
                raise FaceVerificationError(
                    f"Face verification failed. Similarity: {verification_result['similarity']:.3f}"
                )
            
            # Yoklama kaydı oluştur
            attendance_record = AttendanceRecord(
                attendance_id=attendance_id,
                student_id=student_id,
                check_in_time=current_time,
                face_similarity_score=verification_result["similarity"],
                is_verified=True
            )
            
            self.db.add(attendance_record)
            self.db.commit()
            self.db.refresh(attendance_record)
            
            return {
                "success": True,
                "message": "Attendance recorded successfully",
                "record_id": attendance_record.record_id,
                "check_in_time": attendance_record.check_in_time.isoformat(),
                "similarity_score": verification_result["similarity"],
                "student_name": enrollment.student.user.full_name
            }
            
        except Exception as e:
            raise FaceVerificationError(f"Face verification error: {str(e)}")
    
    # ==================== ATTENDANCE REPORTING ====================
    
    def get_attendance_records(
        self,
        attendance_id: int,
        instructor_id: Optional[int] = None
    ) -> List[Dict[str, Any]]:
        """
        Bir yoklama oturumunun kayıtlarını getirir
        
        Args:
            attendance_id: Yoklama oturum ID'si
            instructor_id: Eğitmen ID'si (yetki kontrolü için)
            
        Returns:
            List[Dict]: Yoklama kayıtları
        """
        query = self.db.query(AttendanceRecord).join(
            Student, AttendanceRecord.student_id == Student.student_id
        ).join(Attendance).filter(
            AttendanceRecord.attendance_id == attendance_id
        )
        
        # Eğitmen yetki kontrolü
        if instructor_id:
            query = query.join(Course).filter(
                Course.instructor_id == instructor_id
            )
        
        records = query.order_by(AttendanceRecord.check_in_time).all()
        
        result = []
        for record in records:
            result.append({
                "record_id": record.record_id,
                "student_id": record.student_id,
                "student_number": record.student.student_number,
                "student_name": record.student.user.full_name,
                "check_in_time": record.check_in_time.isoformat(),
                "similarity_score": record.face_similarity_score,
                "is_verified": record.is_verified
            })
        
        return result
    
    def get_student_attendance_history(
        self,
        student_id: int,
        course_id: Optional[int] = None,
        limit: int = 50
    ) -> List[Dict[str, Any]]:
        """
        Bir öğrencinin yoklama geçmişini getirir
        
        Args:
            student_id: Öğrenci ID'si
            course_id: Ders ID'si (opsiyonel, belirli ders için)
            limit: Maksimum kayıt sayısı
            
        Returns:
            List[Dict]: Yoklama geçmişi
        """
        query = self.db.query(AttendanceRecord).join(
            Attendance
        ).join(Course).filter(
            AttendanceRecord.student_id == student_id
        )
        
        if course_id:
            query = query.filter(Course.course_id == course_id)
        
        records = query.order_by(
            desc(AttendanceRecord.check_in_time)
        ).limit(limit).all()
        
        result = []
        for record in records:
            result.append({
                "record_id": record.record_id,
                "course_id": record.attendance.course_id,
                "course_name": record.attendance.course.course_name,
                "session_name": record.attendance.session_name,
                "check_in_time": record.check_in_time.isoformat(),
                "similarity_score": record.face_similarity_score,
                "is_verified": record.is_verified
            })
        
        return result
    
    def calculate_attendance_statistics(
        self,
        course_id: int,
        instructor_id: Optional[int] = None
    ) -> Dict[str, Any]:
        """
        Bir ders için yoklama istatistiklerini hesaplar
        
        Args:
            course_id: Ders ID'si
            instructor_id: Eğitmen ID'si (yetki kontrolü için)
            
        Returns:
            Dict: Yoklama istatistikleri
        """
        # Eğitmen yetki kontrolü
        if instructor_id:
            course = self.db.query(Course).filter(
                and_(
                    Course.course_id == course_id,
                    Course.instructor_id == instructor_id
                )
            ).first()
            
            if not course:
                raise AttendanceNotFoundError("Course not found or unauthorized")
        
        # Toplam oturum sayısı
        total_sessions = self.db.query(Attendance).filter(
            Attendance.course_id == course_id
        ).count()
        
        # Aktif oturum sayısı
        active_sessions = self.db.query(Attendance).filter(
            and_(
                Attendance.course_id == course_id,
                Attendance.is_active == True
            )
        ).count()
        
        # Kayıtlı öğrenci sayısı
        enrolled_students = self.db.query(CourseEnrollment).filter(
            and_(
                CourseEnrollment.course_id == course_id,
                CourseEnrollment.enrollment_status == "active"
            )
        ).count()
        
        # Toplam yoklama kayıt sayısı
        total_records = self.db.query(AttendanceRecord).join(
            Attendance
        ).filter(
            Attendance.course_id == course_id
        ).count()
        
        # Ortalama katılım oranı
        if total_sessions > 0 and enrolled_students > 0:
            expected_total = total_sessions * enrolled_students
            attendance_rate = (total_records / expected_total) * 100
        else:
            attendance_rate = 0.0
        
        return {
            "course_id": course_id,
            "total_sessions": total_sessions,
            "active_sessions": active_sessions,
            "enrolled_students": enrolled_students,
            "total_attendance_records": total_records,
            "attendance_rate_percentage": round(attendance_rate, 2)
        }