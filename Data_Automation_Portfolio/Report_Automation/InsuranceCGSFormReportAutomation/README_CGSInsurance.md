# 📊 Report Automation: Monitoring CGS Form MP & MPP

## 📝 Overview  
Report automation ini bertujuan untuk memonitor semua pengajuan cabang untuk pencairan melalui form **CGS Tipe MP** dan **CGS Tipe MPP**. Sebelumnya, tim harus melakukan pengecekan secara manual satu per satu melalui sistem, yang memakan waktu dan berpotensi menyebabkan kesalahan. Dengan otomatisasi ini, proses monitoring menjadi lebih efisien dan akurat.

## 📄 CGS Form Types  
- **CGS Tipe MPP (Memo Permohonan Pembayaran)**:  
  Form pengajuan oleh cabang untuk pencairan dana klaim bagi konsumen yang pengajuannya telah disetujui.  
- **CGS Tipe MP (Memo Persetujuan)**:  
  Form pengajuan cabang untuk penghapusan hutang konsumen asuransi akibat hasil minus karena konsumen tidak melakukan pembayaran.

## 📌 Assignment  
✅ **Format Laporan**: CSV, dikompresi dalam file RAR  
✅ **Frekuensi Pengiriman**:  
   - **07:00 WIB**  
   - **14:00 WIB**  
✅ **Cutoff Data**:  
   - **Email 07:00**: Data dari **1 Januari 2024** hingga **H-1 pukul 21:00**  
   - **Email 14:00**: Data dari **1 Januari 2024** hingga **H pukul 13:00**  
✅ **Filter Data**:  
   - Menampilkan **semua status**, kecuali **Correction** dan **Reject**  
   - Data harus **akurat** dan sesuai dengan **paging dari sistem CGS Form**  

## ⚙️ Automation Mechanism  
🚀 Otomatisasi dilakukan menggunakan **SQL Server Agent Job Scheduler**  
🛠️ Data diekstrak melalui **stored procedure**  
📂 File CSV dikompresi menggunakan **WinRAR**  
📧 File hasil kompresi dikirim melalui **email otomatis**  

## Tampilan Email

![CgsEmail](InsuranceCGSFormReportAutomation/Images/CGSEMAIL.png)

## 📌 Notes  
⚠️ Data dalam laporan ini hanya merupakan **sampel** dan telah **disamarkan** demi menjaga kerahasiaan informasi.  

Jika ada pertanyaan atau pembaruan yang diperlukan, silakan hubungi tim terkait.  
