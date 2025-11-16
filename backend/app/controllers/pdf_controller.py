from fastapi import UploadFile, HTTPException
from fastapi.responses import FileResponse
from pathlib import Path
from app.services import PDFCompressionService
from app.models import PDFResponse


class PDFController:
    """Controller for handling PDF compression requests"""

    # Maximum file size: 100MB
    MAX_FILE_SIZE = 100 * 1024 * 1024  # 100MB in bytes

    def __init__(self):
        self.pdf_service = PDFCompressionService()

    async def compress_pdf(self, file: UploadFile, quality: str = "medium") -> PDFResponse:
        """
        Handle PDF compression request

        Args:
            file: Uploaded PDF file

        Returns:
            PDFResponse with compression details

        Raises:
            HTTPException: If file is not a PDF or compression fails
        """
        # Validate file type
        if not file.filename.lower().endswith('.pdf'):
            raise HTTPException(status_code=400, detail="Only PDF files are allowed")

        # Validate quality parameter
        valid_qualities = ["low", "medium", "high", "maximum"]
        if quality not in valid_qualities:
            raise HTTPException(
                status_code=400,
                detail=f"Invalid quality. Must be one of: {', '.join(valid_qualities)}"
            )

        try:
            # Read file content
            file_content = await file.read()

            # Validate file size
            file_size = len(file_content)
            if file_size > self.MAX_FILE_SIZE:
                max_size_mb = self.MAX_FILE_SIZE / (1024 * 1024)
                raise HTTPException(
                    status_code=400,
                    detail=f"File too large. Maximum size allowed is {max_size_mb:.0f}MB"
                )

            # Save uploaded file
            uploaded_file_path = self.pdf_service.save_uploaded_file(
                file_content, file.filename
            )

            # Compress PDF with specified quality
            compressed_path, original_size, compressed_size = self.pdf_service.compress_pdf(
                uploaded_file_path, quality
            )

            # Calculate compression ratio
            compression_ratio = self.pdf_service.get_compression_ratio(
                original_size, compressed_size
            )

            # Clean up uploaded file
            self.pdf_service.cleanup_file(uploaded_file_path)

            # Create response
            response = PDFResponse(
                filename=compressed_path.name,
                original_size=original_size,
                compressed_size=compressed_size,
                compression_ratio=compression_ratio,
                download_url=f"/api/download/{compressed_path.name}"
            )

            return response

        except Exception as e:
            # Clean up files on error
            if 'uploaded_file_path' in locals():
                self.pdf_service.cleanup_file(uploaded_file_path)
            if 'compressed_path' in locals():
                self.pdf_service.cleanup_file(compressed_path)

            raise HTTPException(status_code=500, detail=f"Error compressing PDF: {str(e)}")

    def download_pdf(self, filename: str) -> FileResponse:
        """
        Handle PDF download request

        Args:
            filename: Name of the compressed PDF file

        Returns:
            FileResponse with the PDF file

        Raises:
            HTTPException: If file not found
        """
        file_path = Path("compressed") / filename

        if not file_path.exists():
            raise HTTPException(status_code=404, detail="File not found")

        return FileResponse(
            path=str(file_path),
            media_type='application/pdf',
            filename=filename
        )
