
# 📊 Report Automation Premi Asuransi DIFF  

## 🚀 Tujuan  
Automated reporting ini bertujuan untuk membantu **tim asuransi** dalam mengontrol pengajuan cover asuransi dengan mengidentifikasi **perbedaan nominal premi** yang dibayarkan oleh konsumen saat proses akuisisi dengan premi yang akan dibayarkan oleh **PT MCF dan MAF** kepada rekan maskapai asuransi.  

## 🚀 Assignment  
Output dari automated reporting ini berupa **laporan harian** yang dikirimkan secara otomatis melalui email. Laporan ini menampilkan **data perbedaan nominal premi**, membantu tim asuransi dalam **pengawasan dan pengambilan keputusan**.  

---

## 📌 Alur Proses  

### 1️⃣ Membuat Stored Procedure untuk Generate Data  
Stored Procedure ini bertugas untuk:  
✔ Mengambil data dari database dan menyimpannya dalam tabel yang siap digunakan.  
✔ Memastikan bahwa data dalam format yang sesuai untuk dianalisis lebih lanjut.  

### 2️⃣ Membuat Stored Procedure untuk Proses Kirim Email  
Stored Procedure ini bertanggung jawab untuk mengirimkan hasil perbandingan premi melalui email ke tim asuransi. Proses ini mencakup:  
✔ Menjalankan query untuk menghasilkan data premi dalam format **CSV**.  
✔ Mengompres file hasil query agar lebih ringkas.  
✔ Mengambil informasi penerima email dari database untuk pengiriman otomatis.  

### 3️⃣ Menjadwalkan Pengiriman Email dengan Job Schedule  
Proses ini mengotomatiskan pengiriman laporan dengan menjalankan Stored Procedure email menggunakan **Job Schedule**. Dengan ini, laporan premi dapat dikirim secara berkala tanpa perlu intervensi manual.  

---

## 📌 Catatan  
💡 **Data yang digunakan hanya sampel dan telah dianonimkan.**  
📌 **Silakan coba query ini pada dataset lain untuk eksplorasi lebih lanjut.**  
