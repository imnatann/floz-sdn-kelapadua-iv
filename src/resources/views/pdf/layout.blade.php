<!DOCTYPE html>
<html>
<head>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
    <title>Laporan Hasil Belajar</title>
    <style>
        @page { margin: 2cm; }
        body { font-family: sans-serif; font-size: 11pt; line-height: 1.3; }
        
        .header { 
            text-align: center; 
            border-bottom: 3px double #000; 
            padding-bottom: 10px; 
            margin-bottom: 25px; 
        }
        .header h2 { margin: 0; font-size: 16pt; text-transform: uppercase; }
        .header p { margin: 2px 0; font-size: 10pt; }
        
        .student-info { width: 100%; margin-bottom: 20px; }
        .student-info td { padding: 3px 0; vertical-align: top; border: none; }
        .label { width: 140px; }
        .separator { width: 10px; }
        
        table.grades { width: 100%; border-collapse: collapse; margin-bottom: 20px; }
        table.grades th, table.grades td { 
            border: 1px solid #000; 
            padding: 6px; 
            vertical-align: middle; 
        }
        table.grades th { background-color: #f0f0f0; text-align: center; font-weight: bold; }
        
        .center { text-align: center; }
        .bold { font-weight: bold; }
        
        .footer { margin-top: 30px; width: 100%; }
        .footer td { border: none; text-align: center; vertical-align: top; padding-top: 20px; }
        .signature-box { height: 80px; }
    </style>
</head>
<body>
    <div class="header">
        <h2>Laporan Hasil Belajar</h2>
        <h2>{{ $tenant->name }}</h2>
        <p>{{ $tenant->address }}</p>
        <p>Email: {{ $tenant->email }} | Telp: {{ $tenant->phone }}</p>
    </div>

    @yield('content')
</body>
</html>
