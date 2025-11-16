import os
import uuid
import subprocess
from pathlib import Path
from typing import Tuple, Literal
import fitz  # PyMuPDF

# Compression quality levels
CompressionQuality = Literal["low", "medium", "high", "maximum"]


class PDFCompressionService:
    """Service for handling PDF compression operations"""

    def __init__(self, upload_dir: str = "uploads", compressed_dir: str = "compressed"):
        self.upload_dir = Path(upload_dir)
        self.compressed_dir = Path(compressed_dir)

        # Create directories if they don't exist
        self.upload_dir.mkdir(exist_ok=True)
        self.compressed_dir.mkdir(exist_ok=True)

    def _find_ghostscript(self) -> str:
        """Find Ghostscript executable path"""
        import glob

        # Common Ghostscript paths on Windows
        common_paths = [
            r'C:\Program Files\gs\gs*\bin\gswin64c.exe',
            r'C:\Program Files (x86)\gs\gs*\bin\gswin64c.exe',
            r'C:\Program Files\gs\gs*\bin\gswin32c.exe',
            r'C:\Program Files (x86)\gs\gs*\bin\gswin32c.exe',
        ]

        # Try to find Ghostscript in common paths
        for pattern in common_paths:
            matches = glob.glob(pattern)
            if matches:
                return matches[0]

        # Try system PATH
        gs_commands = ['gswin64c', 'gswin32c', 'gs']
        for cmd in gs_commands:
            try:
                result = subprocess.run([cmd, '-v'], capture_output=True, timeout=5)
                if result.returncode == 0:
                    return cmd
            except:
                continue

        return None

    def _compress_with_ghostscript(self, file_path: Path, compressed_path: Path, quality: str) -> bool:
        """Compress PDF using Ghostscript (professional quality)"""
        # Find Ghostscript executable
        gs_cmd = self._find_ghostscript()
        if not gs_cmd:
            print("[ERROR] Ghostscript not found!")
            return False

        print(f"[OK] Ghostscript found at: {gs_cmd}")

        # Ghostscript quality settings
        gs_settings = {
            "low": "/screen",      # 72 DPI - maximum compression
            "medium": "/ebook",    # 150 DPI - balanced
            "high": "/printer",    # 300 DPI - high quality
            "maximum": "/prepress" # 300 DPI - maximum quality
        }

        pdf_setting = gs_settings.get(quality, "/ebook")

        try:
            # Use minimal command for maximum compression
            cmd = [
                gs_cmd,
                '-sDEVICE=pdfwrite',
                '-dCompatibilityLevel=1.4',
                f'-dPDFSETTINGS={pdf_setting}',
                '-dNOPAUSE',
                '-dBATCH',
                '-dQUIET',
                f'-sOutputFile={compressed_path}',
                str(file_path)
            ]

            print(f"[RUNNING] Ghostscript with quality: {quality} ({pdf_setting})")
            result = subprocess.run(cmd, capture_output=True, timeout=120)

            if result.returncode == 0 and compressed_path.exists():
                print("[OK] Ghostscript compression successful!")
                return True
            else:
                print(f"[ERROR] Ghostscript failed. Return code: {result.returncode}")
                if result.stderr:
                    print(f"Error: {result.stderr.decode()}")
                return False
        except Exception as e:
            print(f"[ERROR] Ghostscript exception: {e}")
            return False

    def compress_pdf(self, file_path: Path, quality: CompressionQuality = "medium") -> Tuple[Path, int, int]:
        """
        Compress a PDF file using Ghostscript (preferred) or PyMuPDF (fallback)

        Args:
            file_path: Path to the input PDF file
            quality: Compression quality level (low, medium, high, maximum)
                    - low: Maximum compression, lower quality (suitable for screen viewing)
                    - medium: Balanced compression and quality (recommended)
                    - high: Higher quality, less compression (suitable for printing)
                    - maximum: Highest quality, minimal compression (archive quality)

        Returns:
            Tuple of (compressed_file_path, original_size, compressed_size)
        """
        # Generate unique filename for compressed file
        unique_id = str(uuid.uuid4())
        original_filename = file_path.stem
        compressed_filename = f"{original_filename}_compressed_{unique_id}.pdf"
        compressed_path = self.compressed_dir / compressed_filename

        # Get original file size
        original_size = file_path.stat().st_size

        # Try Ghostscript first (professional compression)
        if self._compress_with_ghostscript(file_path, compressed_path, quality):
            compressed_size = compressed_path.stat().st_size
            return compressed_path, original_size, compressed_size

        # Fallback to PyMuPDF
        quality_settings = {
            "low": {"image_quality": 50, "deflate": 1},
            "medium": {"image_quality": 70, "deflate": 1},
            "high": {"image_quality": 85, "deflate": 0},
            "maximum": {"image_quality": 95, "deflate": 0}
        }

        settings = quality_settings.get(quality, quality_settings["medium"])

        doc = fitz.open(str(file_path))

        for page_num in range(len(doc)):
            page = doc[page_num]
            image_list = page.get_images(full=True)

            for img_index, img_info in enumerate(image_list):
                xref = img_info[0]

                try:
                    base_image = doc.extract_image(xref)
                    image_bytes = base_image["image"]

                    from PIL import Image
                    import io

                    img = Image.open(io.BytesIO(image_bytes))

                    if img.mode == 'RGBA':
                        background = Image.new('RGB', img.size, (255, 255, 255))
                        background.paste(img, mask=img.split()[3])
                        img = background
                    elif img.mode not in ('RGB', 'L'):
                        img = img.convert('RGB')

                    max_size = 2000 if quality == "low" else 3000 if quality == "medium" else 4000
                    if img.width > max_size or img.height > max_size:
                        ratio = min(max_size / img.width, max_size / img.height)
                        new_size = (int(img.width * ratio), int(img.height * ratio))
                        img = img.resize(new_size, Image.Resampling.LANCZOS)

                    img_bytes = io.BytesIO()
                    img.save(img_bytes, format='JPEG', quality=settings["image_quality"], optimize=True)
                    img_bytes = img_bytes.getvalue()

                    doc.update_stream(xref, img_bytes)

                except Exception as e:
                    continue

        doc.save(
            str(compressed_path),
            garbage=4,
            deflate=True,
            clean=True,
            no_new_id=True
        )

        doc.close()

        compressed_size = compressed_path.stat().st_size
        return compressed_path, original_size, compressed_size

    def save_uploaded_file(self, file_content: bytes, filename: str) -> Path:
        """
        Save uploaded file to upload directory

        Args:
            file_content: File content in bytes
            filename: Original filename

        Returns:
            Path to saved file
        """
        # Generate unique filename
        unique_id = str(uuid.uuid4())
        file_extension = Path(filename).suffix
        unique_filename = f"{Path(filename).stem}_{unique_id}{file_extension}"
        file_path = self.upload_dir / unique_filename

        # Save file
        with open(file_path, 'wb') as f:
            f.write(file_content)

        return file_path

    def cleanup_file(self, file_path: Path) -> None:
        """
        Delete a file

        Args:
            file_path: Path to file to delete
        """
        try:
            if file_path.exists():
                file_path.unlink()
        except Exception as e:
            print(f"Error deleting file {file_path}: {e}")

    def get_compression_ratio(self, original_size: int, compressed_size: int) -> float:
        """
        Calculate compression ratio

        Args:
            original_size: Original file size in bytes
            compressed_size: Compressed file size in bytes

        Returns:
            Compression ratio as percentage
        """
        if original_size == 0:
            return 0.0

        ratio = ((original_size - compressed_size) / original_size) * 100
        return round(ratio, 2)
