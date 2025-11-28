"""Initial migration with all models

Revision ID: 001
Revises: 
Create Date: 2024-11-05 14:30:00.000000

"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision = '001'
down_revision = None
branch_labels = None
depends_on = None


def upgrade() -> None:
    # Create users table
    op.create_table(
        'users',
        sa.Column('user_id', sa.Integer(), nullable=False),
        sa.Column('email', sa.String(length=100), nullable=False),
        sa.Column('password_hash', sa.String(length=255), nullable=False),
        sa.Column('full_name', sa.String(length=100), nullable=False),
        sa.Column('role', sa.String(length=20), nullable=False),
        sa.Column('created_at', sa.DateTime(), server_default=sa.text('CURRENT_TIMESTAMP'), nullable=True),
        sa.Column('updated_at', sa.DateTime(), nullable=True),
        sa.CheckConstraint("role IN ('student', 'instructor')", name='users_role_check'),
        sa.PrimaryKeyConstraint('user_id'),
        sa.UniqueConstraint('email')
    )
    op.create_index(op.f('ix_users_email'), 'users', ['email'], unique=False)
    op.create_index(op.f('ix_users_role'), 'users', ['role'], unique=False)
    op.create_index(op.f('ix_users_user_id'), 'users', ['user_id'], unique=False)

    # Create students table
    op.create_table(
        'students',
        sa.Column('student_id', sa.Integer(), nullable=False),
        sa.Column('user_id', sa.Integer(), nullable=False),
        sa.Column('student_number', sa.String(length=20), nullable=False),
        sa.Column('department', sa.String(length=100), nullable=False),
        sa.Column('class_level', sa.Integer(), nullable=True),
        sa.Column('enrollment_year', sa.Integer(), nullable=False),
        sa.Column('face_data_url', sa.String(length=255), nullable=True),
        sa.Column('profile_image_url', sa.String(length=255), nullable=True),
        sa.Column('total_absences', sa.Integer(), nullable=True, server_default='0'),
        sa.CheckConstraint('class_level BETWEEN 1 AND 4', name='students_class_level_check'),
        sa.ForeignKeyConstraint(['user_id'], ['users.user_id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('student_id'),
        sa.UniqueConstraint('student_number'),
        sa.UniqueConstraint('user_id')
    )
    op.create_index(op.f('ix_students_student_id'), 'students', ['student_id'], unique=False)
    op.create_index(op.f('ix_students_student_number'), 'students', ['student_number'], unique=False)
    op.create_index(op.f('ix_students_user_id'), 'students', ['user_id'], unique=False)

    # Create instructors table
    op.create_table(
        'instructors',
        sa.Column('instructor_id', sa.Integer(), nullable=False),
        sa.Column('user_id', sa.Integer(), nullable=False),
        sa.Column('title', sa.String(length=50), nullable=True),
        sa.Column('office_info', sa.String(length=100), nullable=True),
        sa.Column('profile_image_url', sa.String(length=255), nullable=True),
        sa.ForeignKeyConstraint(['user_id'], ['users.user_id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('instructor_id'),
        sa.UniqueConstraint('user_id')
    )
    op.create_index(op.f('ix_instructors_instructor_id'), 'instructors', ['instructor_id'], unique=False)
    op.create_index(op.f('ix_instructors_user_id'), 'instructors', ['user_id'], unique=False)

    # Create courses table
    op.create_table(
        'courses',
        sa.Column('course_id', sa.Integer(), nullable=False),
        sa.Column('instructor_id', sa.Integer(), nullable=False),
        sa.Column('course_name', sa.String(length=100), nullable=False),
        sa.Column('course_code', sa.String(length=20), nullable=False),
        sa.Column('semester', sa.String(length=20), nullable=False),
        sa.Column('join_code', sa.String(length=10), nullable=False),
        sa.Column('created_at', sa.DateTime(), server_default=sa.text('CURRENT_TIMESTAMP'), nullable=True),
        sa.ForeignKeyConstraint(['instructor_id'], ['instructors.instructor_id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('course_id'),
        sa.UniqueConstraint('course_code'),
        sa.UniqueConstraint('join_code')
    )
    op.create_index(op.f('ix_courses_course_id'), 'courses', ['course_id'], unique=False)
    op.create_index(op.f('ix_courses_instructor_id'), 'courses', ['instructor_id'], unique=False)
    op.create_index(op.f('ix_courses_join_code'), 'courses', ['join_code'], unique=False)

    # Create course_enrollments table
    op.create_table(
        'course_enrollments',
        sa.Column('enrollment_id', sa.Integer(), nullable=False),
        sa.Column('student_id', sa.Integer(), nullable=False),
        sa.Column('course_id', sa.Integer(), nullable=False),
        sa.Column('joined_at', sa.DateTime(), server_default=sa.text('CURRENT_TIMESTAMP'), nullable=True),
        sa.ForeignKeyConstraint(['course_id'], ['courses.course_id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['student_id'], ['students.student_id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('enrollment_id'),
        sa.UniqueConstraint('student_id', 'course_id', name='uq_student_course')
    )
    op.create_index(op.f('ix_course_enrollments_course_id'), 'course_enrollments', ['course_id'], unique=False)
    op.create_index(op.f('ix_course_enrollments_enrollment_id'), 'course_enrollments', ['enrollment_id'], unique=False)
    op.create_index(op.f('ix_course_enrollments_student_id'), 'course_enrollments', ['student_id'], unique=False)

    # Create attendances table
    op.create_table(
        'attendances',
        sa.Column('attendance_id', sa.Integer(), nullable=False),
        sa.Column('course_id', sa.Integer(), nullable=False),
        sa.Column('instructor_id', sa.Integer(), nullable=False),
        sa.Column('attendance_date', sa.DateTime(), server_default=sa.text('CURRENT_TIMESTAMP'), nullable=True),
        sa.Column('is_active', sa.Boolean(), nullable=True, server_default='true'),
        sa.ForeignKeyConstraint(['course_id'], ['courses.course_id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['instructor_id'], ['instructors.instructor_id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('attendance_id')
    )
    op.create_index(op.f('ix_attendances_attendance_id'), 'attendances', ['attendance_id'], unique=False)
    op.create_index(op.f('ix_attendances_course_id'), 'attendances', ['course_id'], unique=False)
    op.create_index(op.f('ix_attendances_instructor_id'), 'attendances', ['instructor_id'], unique=False)

    # Create attendance_records table
    op.create_table(
        'attendance_records',
        sa.Column('record_id', sa.Integer(), nullable=False),
        sa.Column('attendance_id', sa.Integer(), nullable=False),
        sa.Column('student_id', sa.Integer(), nullable=False),
        sa.Column('recognized', sa.Boolean(), nullable=True, server_default='false'),
        sa.Column('accuracy_percentage', sa.Numeric(precision=5, scale=2), nullable=True),
        sa.Column('location_info', sa.String(length=255), nullable=True),
        sa.Column('joined_at', sa.DateTime(), server_default=sa.text('CURRENT_TIMESTAMP'), nullable=True),
        sa.ForeignKeyConstraint(['attendance_id'], ['attendances.attendance_id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['student_id'], ['students.student_id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('record_id'),
        sa.UniqueConstraint('attendance_id', 'student_id', name='uq_attendance_student')
    )
    op.create_index(op.f('ix_attendance_records_attendance_id'), 'attendance_records', ['attendance_id'], unique=False)
    op.create_index(op.f('ix_attendance_records_record_id'), 'attendance_records', ['record_id'], unique=False)
    op.create_index(op.f('ix_attendance_records_student_id'), 'attendance_records', ['student_id'], unique=False)

    # Create assignments table
    op.create_table(
        'assignments',
        sa.Column('assignment_id', sa.Integer(), nullable=False),
        sa.Column('course_id', sa.Integer(), nullable=False),
        sa.Column('instructor_id', sa.Integer(), nullable=False),
        sa.Column('title', sa.String(length=100), nullable=False),
        sa.Column('description', sa.Text(), nullable=True),
        sa.Column('due_date', sa.DateTime(), nullable=False),
        sa.Column('created_at', sa.DateTime(), server_default=sa.text('CURRENT_TIMESTAMP'), nullable=True),
        sa.ForeignKeyConstraint(['course_id'], ['courses.course_id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['instructor_id'], ['instructors.instructor_id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('assignment_id')
    )
    op.create_index(op.f('ix_assignments_assignment_id'), 'assignments', ['assignment_id'], unique=False)
    op.create_index(op.f('ix_assignments_course_id'), 'assignments', ['course_id'], unique=False)
    op.create_index(op.f('ix_assignments_instructor_id'), 'assignments', ['instructor_id'], unique=False)

    # Create assignment_submissions table
    op.create_table(
        'assignment_submissions',
        sa.Column('submission_id', sa.Integer(), nullable=False),
        sa.Column('assignment_id', sa.Integer(), nullable=False),
        sa.Column('student_id', sa.Integer(), nullable=False),
        sa.Column('file_url', sa.String(length=255), nullable=True),
        sa.Column('submitted_at', sa.DateTime(), nullable=True),
        sa.Column('status', sa.String(length=20), nullable=True, server_default='atandı'),
        sa.Column('grade', sa.Numeric(precision=4, scale=2), nullable=True),
        sa.CheckConstraint("status IN ('atandı', 'teslim edilmedi', 'tamamlandı')", name='assignment_submissions_status_check'),
        sa.ForeignKeyConstraint(['assignment_id'], ['assignments.assignment_id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['student_id'], ['students.student_id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('submission_id'),
        sa.UniqueConstraint('assignment_id', 'student_id', name='uq_assignment_student')
    )
    op.create_index(op.f('ix_assignment_submissions_assignment_id'), 'assignment_submissions', ['assignment_id'], unique=False)
    op.create_index(op.f('ix_assignment_submissions_student_id'), 'assignment_submissions', ['student_id'], unique=False)
    op.create_index(op.f('ix_assignment_submissions_submission_id'), 'assignment_submissions', ['submission_id'], unique=False)

    # Create announcements table
    op.create_table(
        'announcements',
        sa.Column('announcement_id', sa.Integer(), nullable=False),
        sa.Column('course_id', sa.Integer(), nullable=False),
        sa.Column('instructor_id', sa.Integer(), nullable=False),
        sa.Column('type', sa.String(length=20), nullable=False),
        sa.Column('title', sa.String(length=100), nullable=False),
        sa.Column('content', sa.Text(), nullable=True),
        sa.Column('attachment_url', sa.String(length=255), nullable=True),
        sa.Column('created_at', sa.DateTime(), server_default=sa.text('CURRENT_TIMESTAMP'), nullable=True),
        sa.CheckConstraint("type IN ('duyuru', 'not', 'kaynak')", name='announcements_type_check'),
        sa.ForeignKeyConstraint(['course_id'], ['courses.course_id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['instructor_id'], ['instructors.instructor_id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('announcement_id')
    )
    op.create_index(op.f('ix_announcements_announcement_id'), 'announcements', ['announcement_id'], unique=False)
    op.create_index(op.f('ix_announcements_course_id'), 'announcements', ['course_id'], unique=False)
    op.create_index(op.f('ix_announcements_instructor_id'), 'announcements', ['instructor_id'], unique=False)

    # Create student_shared_notes table
    op.create_table(
        'student_shared_notes',
        sa.Column('note_id', sa.Integer(), nullable=False),
        sa.Column('student_id', sa.Integer(), nullable=False),
        sa.Column('course_id', sa.Integer(), nullable=False),
        sa.Column('title', sa.String(length=100), nullable=False),
        sa.Column('content', sa.Text(), nullable=True),
        sa.Column('file_url', sa.String(length=255), nullable=True),
        sa.Column('created_at', sa.DateTime(), server_default=sa.text('CURRENT_TIMESTAMP'), nullable=True),
        sa.ForeignKeyConstraint(['course_id'], ['courses.course_id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['student_id'], ['students.student_id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('note_id')
    )
    op.create_index(op.f('ix_student_shared_notes_course_id'), 'student_shared_notes', ['course_id'], unique=False)
    op.create_index(op.f('ix_student_shared_notes_note_id'), 'student_shared_notes', ['note_id'], unique=False)
    op.create_index(op.f('ix_student_shared_notes_student_id'), 'student_shared_notes', ['student_id'], unique=False)

    # Create surveys table
    op.create_table(
        'surveys',
        sa.Column('survey_id', sa.Integer(), nullable=False),
        sa.Column('course_id', sa.Integer(), nullable=False),
        sa.Column('instructor_id', sa.Integer(), nullable=False),
        sa.Column('question', sa.Text(), nullable=False),
        sa.Column('created_at', sa.DateTime(), server_default=sa.text('CURRENT_TIMESTAMP'), nullable=True),
        sa.ForeignKeyConstraint(['course_id'], ['courses.course_id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['instructor_id'], ['instructors.instructor_id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('survey_id')
    )
    op.create_index(op.f('ix_surveys_course_id'), 'surveys', ['course_id'], unique=False)
    op.create_index(op.f('ix_surveys_instructor_id'), 'surveys', ['instructor_id'], unique=False)
    op.create_index(op.f('ix_surveys_survey_id'), 'surveys', ['survey_id'], unique=False)

    # Create survey_responses table
    op.create_table(
        'survey_responses',
        sa.Column('response_id', sa.Integer(), nullable=False),
        sa.Column('survey_id', sa.Integer(), nullable=False),
        sa.Column('student_id', sa.Integer(), nullable=False),
        sa.Column('answer', sa.Text(), nullable=False),
        sa.Column('answered_at', sa.DateTime(), server_default=sa.text('CURRENT_TIMESTAMP'), nullable=True),
        sa.ForeignKeyConstraint(['student_id'], ['students.student_id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['survey_id'], ['surveys.survey_id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('response_id'),
        sa.UniqueConstraint('survey_id', 'student_id', name='uq_survey_student')
    )
    op.create_index(op.f('ix_survey_responses_response_id'), 'survey_responses', ['response_id'], unique=False)
    op.create_index(op.f('ix_survey_responses_student_id'), 'survey_responses', ['student_id'], unique=False)
    op.create_index(op.f('ix_survey_responses_survey_id'), 'survey_responses', ['survey_id'], unique=False)

    # Create tokens table
    op.create_table(
        'tokens',
        sa.Column('token_id', sa.Integer(), nullable=False),
        sa.Column('user_id', sa.Integer(), nullable=False),
        sa.Column('token', sa.Text(), nullable=False),
        sa.Column('expires_at', sa.DateTime(), nullable=False),
        sa.Column('created_at', sa.DateTime(), server_default=sa.text('CURRENT_TIMESTAMP'), nullable=True),
        sa.ForeignKeyConstraint(['user_id'], ['users.user_id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('token_id')
    )
    op.create_index(op.f('ix_tokens_token_id'), 'tokens', ['token_id'], unique=False)
    op.create_index(op.f('ix_tokens_user_id'), 'tokens', ['user_id'], unique=False)


def downgrade() -> None:
    # Drop tables in reverse order
    op.drop_index(op.f('ix_tokens_user_id'), table_name='tokens')
    op.drop_index(op.f('ix_tokens_token_id'), table_name='tokens')
    op.drop_table('tokens')
    
    op.drop_index(op.f('ix_survey_responses_survey_id'), table_name='survey_responses')
    op.drop_index(op.f('ix_survey_responses_student_id'), table_name='survey_responses')
    op.drop_index(op.f('ix_survey_responses_response_id'), table_name='survey_responses')
    op.drop_table('survey_responses')
    
    op.drop_index(op.f('ix_surveys_survey_id'), table_name='surveys')
    op.drop_index(op.f('ix_surveys_instructor_id'), table_name='surveys')
    op.drop_index(op.f('ix_surveys_course_id'), table_name='surveys')
    op.drop_table('surveys')
    
    op.drop_index(op.f('ix_student_shared_notes_student_id'), table_name='student_shared_notes')
    op.drop_index(op.f('ix_student_shared_notes_note_id'), table_name='student_shared_notes')
    op.drop_index(op.f('ix_student_shared_notes_course_id'), table_name='student_shared_notes')
    op.drop_table('student_shared_notes')
    
    op.drop_index(op.f('ix_announcements_instructor_id'), table_name='announcements')
    op.drop_index(op.f('ix_announcements_course_id'), table_name='announcements')
    op.drop_index(op.f('ix_announcements_announcement_id'), table_name='announcements')
    op.drop_table('announcements')
    
    op.drop_index(op.f('ix_assignment_submissions_submission_id'), table_name='assignment_submissions')
    op.drop_index(op.f('ix_assignment_submissions_student_id'), table_name='assignment_submissions')
    op.drop_index(op.f('ix_assignment_submissions_assignment_id'), table_name='assignment_submissions')
    op.drop_table('assignment_submissions')
    
    op.drop_index(op.f('ix_assignments_instructor_id'), table_name='assignments')
    op.drop_index(op.f('ix_assignments_course_id'), table_name='assignments')
    op.drop_index(op.f('ix_assignments_assignment_id'), table_name='assignments')
    op.drop_table('assignments')
    
    op.drop_index(op.f('ix_attendance_records_student_id'), table_name='attendance_records')
    op.drop_index(op.f('ix_attendance_records_record_id'), table_name='attendance_records')
    op.drop_index(op.f('ix_attendance_records_attendance_id'), table_name='attendance_records')
    op.drop_table('attendance_records')
    
    op.drop_index(op.f('ix_attendances_instructor_id'), table_name='attendances')
    op.drop_index(op.f('ix_attendances_course_id'), table_name='attendances')
    op.drop_index(op.f('ix_attendances_attendance_id'), table_name='attendances')
    op.drop_table('attendances')
    
    op.drop_index(op.f('ix_course_enrollments_student_id'), table_name='course_enrollments')
    op.drop_index(op.f('ix_course_enrollments_enrollment_id'), table_name='course_enrollments')
    op.drop_index(op.f('ix_course_enrollments_course_id'), table_name='course_enrollments')
    op.drop_table('course_enrollments')
    
    op.drop_index(op.f('ix_courses_join_code'), table_name='courses')
    op.drop_index(op.f('ix_courses_instructor_id'), table_name='courses')
    op.drop_index(op.f('ix_courses_course_id'), table_name='courses')
    op.drop_table('courses')
    
    op.drop_index(op.f('ix_instructors_user_id'), table_name='instructors')
    op.drop_index(op.f('ix_instructors_instructor_id'), table_name='instructors')
    op.drop_table('instructors')
    
    op.drop_index(op.f('ix_students_user_id'), table_name='students')
    op.drop_index(op.f('ix_students_student_number'), table_name='students')
    op.drop_index(op.f('ix_students_student_id'), table_name='students')
    op.drop_table('students')
    
    op.drop_index(op.f('ix_users_user_id'), table_name='users')
    op.drop_index(op.f('ix_users_role'), table_name='users')
    op.drop_index(op.f('ix_users_email'), table_name='users')
    op.drop_table('users')
