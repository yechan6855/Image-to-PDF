import sys
from PIL import Image
from reportlab.pdfgen import canvas
from reportlab.lib.units import inch

def convert_to_pdf(image_path, pdf_path):
    img = Image.open(image_path)
    img_width, img_height = img.size

    c = canvas.Canvas(pdf_path, pagesize=(img_width, img_height))
    c.drawImage(image_path, 0, 0, width=img_width, height=img_height)
    c.save()

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python convert_to_pdf.py <input_image_path> <output_pdf_path>")
        sys.exit(1)

    input_image_path = sys.argv[1]
    output_pdf_path = sys.argv[2]
    convert_to_pdf(input_image_path, output_pdf_path)
    print(f"PDF saved to: {output_pdf_path}")