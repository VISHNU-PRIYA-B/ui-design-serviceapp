from reportlab.lib.pagesizes import A4
from reportlab.pdfgen import canvas
from reportlab.lib import colors
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import Table, TableStyle
from django.conf import settings
import os

# Register font
FONT_PATH = os.path.join(
    settings.BASE_DIR,
    'service',
    'utils',
    'fonts',
    'DejaVuSans.ttf'
)
pdfmetrics.registerFont(TTFont('DejaVuSans', FONT_PATH))


def create_invoice_pdf(invoice):
    file_name = f"INV-{invoice.repair_request.request_id}.pdf"
    file_path = os.path.join(settings.MEDIA_ROOT, "invoices", file_name)
    os.makedirs(os.path.dirname(file_path), exist_ok=True)

    p = canvas.Canvas(file_path, pagesize=A4)
    width, height = A4
    y = height - 50

    # COMPANY / SEAL / SIGNATURE
    company = None
    seal_path = None
    signature_path = None

    if invoice.repair_request.created_by:
        company = invoice.repair_request.created_by.company_profile

    if company:
        if company.seal:
            seal_path = company.seal.path
        if company.authorized_signature:
            signature_path = company.authorized_signature.path

    #TITLE 
    p.setFont("DejaVuSans", 20)
    p.drawCentredString(width / 2, y, "INVOICE PREVIEW")

    #  INVOICE INFO 
    p.setFont("DejaVuSans", 12)
    y -= 50
    p.drawRightString(
        width - 40,
        height - 80,
        f"Invoice Number: {invoice.invoice_number}"
    )
    p.drawRightString(
        width - 40,
        height - 100,
        f"Generated On: {invoice.generated_on.strftime('%Y-%m-%d')}"
    )

    customer = invoice.repair_request.customer or {}

    customer_name = invoice.repair_request.customer_name

    info_lines = [
        f"Customer Phone: {invoice.repair_request.contact_info}",
        f"Customer Name: {invoice.repair_request.customer_name}",
        f"Item: {invoice.repair_request.item_name}",
        f"Request ID: {invoice.repair_request.request_id}",
    ]

    for line in info_lines:
        p.drawString(50, y, line)
        y -= 20
    y -= 20

    #  ITEMS TABLE 
    # estimation = invoice.estimation
    # if not estimation:
    #     raise Exception("No estimation found for this repair request")

        
    # data = [["Description", "Quantity × Price", "Amount"]]

    # items = estimation.items.all()
    #  ITEMS TABLE  (ALL ESTIMATIONS)
    estimations = invoice.repair_request.estimations.all()

    if not estimations.exists():
        raise Exception("No estimations found for this repair request")

    data = [["Description", "Quantity × Price", "Amount"]]

    items = []
    total = 0

    for est in estimations:
        for item in est.items.all():
            items.append(item)
            total += item.amount

    # for item in items:
    #     data.append([
    #         item.description,
    #         f"{item.quantity} × ₹{item.unit_price}",
    #         f"₹{item.amount}"
    #     ])
    # data.append(["", "Total", f"₹{estimation.total}"])
    for item in items:
        data.append([
            item.description,
            f"{item.quantity} × ₹{item.unit_price}",
            f"₹{item.amount}"
        ])

    data.append(["", "Total", f"₹{total}"])

    table = Table(data, colWidths=[300, 100, 100])
    table.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), colors.lightgrey),
        ('ALIGN', (1, 1), (-1, -1), 'CENTER'),
        ('FONTNAME', (0, 0), (-1, -1), 'DejaVuSans'),
        ('GRID', (0, 0), (-1, -1), 1, colors.black),
        ('BOTTOMPADDING', (0, 0), (-1, 0), 8),
        ('TOPPADDING', (0, 0), (-1, 0), 8),
    ]))

    table.wrapOn(p, width, height)
    table.drawOn(p, 50, y - (20 * len(data)))

    #  SEAL & SIGNATURE 
    base_y = 60

    # SEAL
    if seal_path and os.path.exists(seal_path):
        p.drawImage(
            seal_path,
            60,
            base_y,
            width=120,
            height=120,
            preserveAspectRatio=True,
            mask='auto'
        )

    # SIGNATURE
    if signature_path and os.path.exists(signature_path):
        sig_x = width - 220
        p.drawImage(
            signature_path,
            sig_x,
            base_y + 20,
            width=160,
            height=80,
            preserveAspectRatio=True,
            mask='auto'
        )

        p.setFont("DejaVuSans", 10)
        p.drawString(sig_x + 40, base_y - 7, "Authorized Sign")

    #  SAVE PDF 
    p.showPage()
    p.save()

    #  UPDATE URL 
    pdf_url = f"{settings.MEDIA_URL}invoices/{file_name}"
    invoice.pdf_url = pdf_url
    invoice.save(update_fields=['pdf_url'])

    return pdf_url
