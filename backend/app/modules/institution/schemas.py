from pydantic import BaseModel


class DashboardOverviewResponse(BaseModel):
    total_students: int
    total_alumni: int
    sessions_completed: int
    avg_response_time_hours: float
    avg_session_rating: float


class SkillGapMetric(BaseModel):
    skill: str
    alumni_supply_count: int
    student_demand_count: int
    gap_percentage: float
