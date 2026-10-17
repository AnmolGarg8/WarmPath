from pydantic_settings import BaseSettings, SettingsConfigDict
from pydantic import Field


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=True,
        extra="ignore",
    )

    # Core Infrastructure
    DATABASE_URL: str = "postgresql+asyncpg://warmpath:warmpath_password@localhost:5432/warmpath"
    REDIS_URL: str = "redis://localhost:6379/0"
    ENVIRONMENT: str = "development"
    DEBUG: bool = True

    # Security & Auth
    JWT_SECRET: str = "default-insecure-jwt-secret-replace-in-production-min32chars"
    ACCESS_TOKEN_MINUTES: int = 60
    REFRESH_TOKEN_DAYS: int = 30

    # Email / SMTP
    SMTP_HOST: str = "localhost"
    SMTP_PORT: int = 1025
    SMTP_USER: str = ""
    SMTP_PASSWORD: str = ""
    SMTP_FROM: str = "no-reply@warmpath.org"

    # AI (Gemini)
    GEMINI_API_KEY: str = ""
    GEMINI_TEXT_MODEL: str = "gemini-1.5-flash"
    GEMINI_EMBED_MODEL: str = "text-embedding-004"

    # Payments (Razorpay - Test Mode)
    RAZORPAY_KEY_ID: str = ""
    RAZORPAY_KEY_SECRET: str = ""
    RAZORPAY_WEBHOOK_SECRET: str = ""

    # Push & Video
    FCM_SERVICE_ACCOUNT_PATH: str = ""
    JITSI_BASE_URL: str = "https://meet.jit.si"

    # Domain Defaults: Rating Bands & Payouts
    PRIOR_MEAN: float = 4.0
    PRIOR_WEIGHT: int = 5
    TRUSTED_MIN_AVG: float = 4.2
    TRUSTED_MIN_SESSIONS: int = 5
    TOP_RATED_MIN_AVG: float = 4.6
    TOP_RATED_MIN_SESSIONS: int = 10
    TOP_RATED_MIN_COMPLETION: float = 0.90

    PAYOUT_SHARE_RISING: float = 0.60
    PAYOUT_SHARE_TRUSTED: float = 0.70
    PAYOUT_SHARE_TOP_RATED: float = 0.80

    # Plans and Pricing (INR)
    PLAN_CAMPUS_PRICE: int = 0
    PLAN_STANDARD_PRICE: int = 299
    PLAN_STANDARD_CREDITS: int = 1
    PLAN_HIGH_PRICE: int = 499
    PLAN_HIGH_CREDITS: int = 2
    PLAN_PREMIUM_PRICE: int = 899
    PLAN_PREMIUM_CREDITS: int = 4

    # Booking Horizons (Days)
    BOOKING_HORIZON_STANDARD_DAYS: int = 3
    BOOKING_HORIZON_HIGH_DAYS: int = 14
    BOOKING_HORIZON_PREMIUM_DAYS: int = 30

    # Request Priorities
    PRIORITY_STANDARD: int = 1
    PRIORITY_HIGH: int = 2
    PRIORITY_PREMIUM: int = 3

    # Session Rules
    SESSION_MIN_CALL_DURATION_MINUTES: int = 5
    DISPUTE_WINDOW_HOURS: int = 48
    AUTO_REFUND_TIMEOUT_HOURS: int = 72

    # Trust Levels & Daily Request Limits
    DAILY_LIMIT_NEW: int = 3
    DAILY_LIMIT_VERIFIED: int = 10
    DAILY_LIMIT_ESTABLISHED: int = 25
    DAILY_LIMIT_RESTRICTED: int = 1

    # Matching Weights
    MATCH_WEIGHT_EXPERTISE: float = 0.35
    MATCH_WEIGHT_INTENT: float = 0.25
    MATCH_WEIGHT_AFFINITY: float = 0.15
    MATCH_WEIGHT_AVAILABILITY: float = 0.10
    MATCH_WEIGHT_RATING: float = 0.10
    MATCH_WEIGHT_RESPONSE_ODDS: float = 0.05


settings = Settings()
