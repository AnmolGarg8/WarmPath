import uuid
from pydantic import BaseModel


class CashoutRequest(BaseModel):
    credits_to_cashout: int
    account_details: dict


class DonateCreditsRequest(BaseModel):
    credits_to_donate: int


class AllocateSeatsRequest(BaseModel):
    student_emails: list[str]
    seat_count: int
