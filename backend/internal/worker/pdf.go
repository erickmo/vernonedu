package worker

import (
	"bytes"
	"fmt"
	"time"

	"github.com/jung-kurt/gofpdf"
)

// PDF rendering constants — keep all visual strings/numbers named.
const (
	pdfTitle             = "Certificate of Completion"
	pdfIssuer            = "VernonEdu"
	pdfBodyLine          = "This certifies that"
	pdfCourseLine        = "has successfully completed the course"
	pdfDateLine          = "Issued on"
	pdfVerifyLine        = "Verify at"
	pdfDateLayout        = "January 2, 2006"
	pdfMargin            = 20.0
	pdfTitleFontSize     = 28
	pdfHeaderFontSize    = 14
	pdfNameFontSize      = 22
	pdfBodyFontSize      = 14
	pdfFooterFontSize    = 10
	pdfFontFamily        = "Arial"
	pdfPageOrientation   = "L"
	pdfPageSizeUnit      = "mm"
	pdfPageSize          = "A4"
	pdfTextAlignCenter   = "C"
	pdfNoBorder          = ""
	pdfLineHeightDefault = 10
)

// CertificatePDFData holds the inputs needed to render a certificate.
type CertificatePDFData struct {
	StudentName    string
	CourseName     string
	CertNumber     string
	IssuedAt       time.Time
	VerificationURL string
}

// PDFGenerator renders certificate PDFs.
type PDFGenerator interface {
	Render(data CertificatePDFData) ([]byte, error)
}

type gofpdfGenerator struct{}

// NewPDFGenerator returns a gofpdf-backed PDFGenerator.
func NewPDFGenerator() PDFGenerator { return &gofpdfGenerator{} }

func (g *gofpdfGenerator) Render(data CertificatePDFData) ([]byte, error) {
	pdf := gofpdf.New(pdfPageOrientation, pdfPageSizeUnit, pdfPageSize, "")
	pdf.SetMargins(pdfMargin, pdfMargin, pdfMargin)
	pdf.AddPage()

	g.writeTitle(pdf)
	g.writeBody(pdf, data)
	g.writeFooter(pdf, data)

	var buf bytes.Buffer
	if err := pdf.Output(&buf); err != nil {
		return nil, fmt.Errorf("pdf render: %w", err)
	}
	return buf.Bytes(), nil
}

func (g *gofpdfGenerator) writeTitle(pdf *gofpdf.Fpdf) {
	pdf.SetFont(pdfFontFamily, "B", pdfTitleFontSize)
	pdf.CellFormat(0, 20, pdfTitle, pdfNoBorder, 1, pdfTextAlignCenter, false, 0, "")
	pdf.Ln(8)
	pdf.SetFont(pdfFontFamily, "", pdfHeaderFontSize)
	pdf.CellFormat(0, 8, pdfIssuer, pdfNoBorder, 1, pdfTextAlignCenter, false, 0, "")
	pdf.Ln(8)
}

func (g *gofpdfGenerator) writeBody(pdf *gofpdf.Fpdf, data CertificatePDFData) {
	pdf.SetFont(pdfFontFamily, "", pdfBodyFontSize)
	pdf.CellFormat(0, pdfLineHeightDefault, pdfBodyLine, pdfNoBorder, 1, pdfTextAlignCenter, false, 0, "")
	pdf.Ln(4)
	pdf.SetFont(pdfFontFamily, "B", pdfNameFontSize)
	pdf.CellFormat(0, 14, data.StudentName, pdfNoBorder, 1, pdfTextAlignCenter, false, 0, "")
	pdf.Ln(4)
	pdf.SetFont(pdfFontFamily, "", pdfBodyFontSize)
	pdf.CellFormat(0, pdfLineHeightDefault, pdfCourseLine, pdfNoBorder, 1, pdfTextAlignCenter, false, 0, "")
	pdf.Ln(2)
	pdf.SetFont(pdfFontFamily, "B", pdfBodyFontSize)
	pdf.CellFormat(0, pdfLineHeightDefault, data.CourseName, pdfNoBorder, 1, pdfTextAlignCenter, false, 0, "")
	pdf.Ln(8)
}

func (g *gofpdfGenerator) writeFooter(pdf *gofpdf.Fpdf, data CertificatePDFData) {
	pdf.SetFont(pdfFontFamily, "", pdfBodyFontSize)
	pdf.CellFormat(0, pdfLineHeightDefault,
		fmt.Sprintf("%s %s", pdfDateLine, data.IssuedAt.Format(pdfDateLayout)),
		pdfNoBorder, 1, pdfTextAlignCenter, false, 0, "")
	pdf.Ln(4)
	pdf.SetFont(pdfFontFamily, "", pdfFooterFontSize)
	pdf.CellFormat(0, 6, fmt.Sprintf("Certificate No: %s", data.CertNumber),
		pdfNoBorder, 1, pdfTextAlignCenter, false, 0, "")
	pdf.CellFormat(0, 6, fmt.Sprintf("%s: %s", pdfVerifyLine, data.VerificationURL),
		pdfNoBorder, 1, pdfTextAlignCenter, false, 0, "")
}
