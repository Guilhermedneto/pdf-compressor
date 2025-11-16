from fastapi import APIRouter, UploadFile, File
from fastapi.responses import FileResponse
from app.controllers import PDFController
from app.models import PDFResponse, ErrorResponse


router = APIRouter(prefix="/api", tags=["PDF Operations"])
pdf_controller = PDFController()


@router.post("/compress", response_model=PDFResponse, responses={400: {"model": ErrorResponse}, 500: {"model": ErrorResponse}})
async def compress_pdf(
    file: UploadFile = File(...),
    quality: str = "medium"
):
    """
    Compress a PDF file

    - **file**: PDF file to compress
    - **quality**: Compression quality level (low, medium, high, maximum)
        - low: Maximum compression, lower quality (suitable for screen viewing)
        - medium: Balanced compression and quality (recommended)
        - high: Higher quality, less compression (suitable for printing)
        - maximum: Highest quality, minimal compression (archive quality)
    """
    return await pdf_controller.compress_pdf(file, quality)


@router.get("/download/{filename}")
async def download_pdf(filename: str):
    """
    Download a compressed PDF file

    - **filename**: Name of the compressed file
    """
    return pdf_controller.download_pdf(filename)
