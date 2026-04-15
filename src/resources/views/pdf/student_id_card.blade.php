<!DOCTYPE html>
<html>
<head>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
    <title>Kartu Pelajar - {{ $student->name }}</title>
    <style>
        body {
            font-family: sans-serif;
            margin: 0;
            padding: 20px;
        }
        .card {
            width: 323px; /* 85.6mm */
            height: 204px; /* 53.98mm */
            border: 1px solid #000;
            border-radius: 10px;
            padding: 15px;
            position: relative;
            background: #f8f9fa;
        }
        .header {
            text-align: center;
            border-bottom: 2px solid #22c55e;
            padding-bottom: 5px;
            margin-bottom: 10px;
        }
        .school-name {
            font-size: 14px;
            font-weight: bold;
            color: #15803d;
            text-transform: uppercase;
        }
        .card-title {
            font-size: 10px;
            letter-spacing: 2px;
            margin-top: 2px;
        }
        .content {
            display: table;
            width: 100%;
        }
        .photo {
            display: table-cell;
            width: 80px;
            vertical-align: top;
        }
        .photo-box {
            width: 70px;
            height: 90px;
            background: #e2e8f0;
            border: 1px solid #cbd5e1;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 10px;
            color: #64748b;
        }
        .details {
            display: table-cell;
            vertical-align: top;
            padding-left: 10px;
        }
        .label {
            font-size: 9px;
            color: #64748b;
        }
        .value {
            font-size: 11px;
            font-weight: bold;
            color: #1e293b;
            margin-bottom: 4px;
        }
        .qr-code {
            position: absolute;
            bottom: 15px;
            right: 15px;
            width: 50px;
            height: 50px;
            border: 1px dashed #94a3b8;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 8px;
            color: #94a3b8;
        }
        .footer {
            position: absolute;
            bottom: 5px;
            left: 15px;
            font-size: 8px;
            color: #94a3b8;
        }
    </style>
</head>
<body>
    <div class="card">
        <div class="header">
            <div class="school-name">{{ $student->class?->academicYear?->tenant?->name ?? 'SEKOLAH FLOZ' }}</div>
            <div class="card-title">KARTU PELAJAR</div>
        </div>
        
        <div class="content">
            <div class="photo">
                <div class="photo-box">
                    @if($student->photo_url)
                        <img src="{{ public_path('storage/'.$student->photo_url) }}" style="width:100%; height:100%; object-fit:cover;">
                    @else
                        FOTO
                    @endif
                </div>
            </div>
            <div class="details">
                <div class="label">Nama</div>
                <div class="value">{{ $student->name }}</div>
                
                <div class="label">NIS / NISN</div>
                <div class="value">{{ $student->nis }} / {{ $student->nisn ?? '-' }}</div>
                
                <div class="label">Tempat, Tanggal Lahir</div>
                <div class="value">{{ $student->birth_place }}, {{ $student->birth_date?->format('d-m-Y') }}</div>
            </div>
        </div>

        <div class="qr-code">
            QR CODE
        </div>
        
        <div class="footer">
            Berlaku Selama Menjadi Siswa
        </div>
    </div>
</body>
</html>
