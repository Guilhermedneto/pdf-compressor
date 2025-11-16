from pydantic import BaseModel
from typing import Optional


class PDFResponse(BaseModel):
    """Model for PDF compression response"""
    filename: str
    original_size: int
    compressed_size: int
    compression_ratio: float
    download_url: str


class ErrorResponse(BaseModel):
    """Model for error responses"""
    detail: str
