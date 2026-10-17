from pydantic import BaseModel


class TimeSlot(BaseModel):
    day_of_week: int  # 0=Monday, 6=Sunday
    start_time: str   # "18:00"
    end_time: str     # "20:00"


class AvailabilityUpdate(BaseModel):
    weekly_capacity: int = 2
    slots: list[TimeSlot] = []


class OnlineWindowRequest(BaseModel):
    duration_minutes: int = 30
