from pydantic import BaseModel


class ResumeProfileUpdate(BaseModel):
    skills: list[str] = []
    headline: str | None = None
    summary: str | None = None


class IntentUpdate(BaseModel):
    goal: str
    target_domains: list[str] = []
    notes: str | None = None


class ConsentsUpdate(BaseModel):
    resume_storage_consent: bool = True
    ai_matching_consent: bool = True
