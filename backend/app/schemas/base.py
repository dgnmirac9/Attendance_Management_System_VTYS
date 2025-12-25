from pydantic import BaseModel, ConfigDict
from pydantic.alias_generators import to_camel

class CamelCaseModel(BaseModel):
    """
    Base model that automatically aliases snake_case fields to camelCase
    for JSON serialization/deserialization.
    """
    model_config = ConfigDict(
        alias_generator=to_camel,
        populate_by_name=True,
        from_attributes=True
    )
