@extends('pdf.layout')

@section('content')
<table class="student-info">
    <tr>
        <td class="label">Nama Peserta Didik</td><td class="separator">:</td><td class="bold">{{ $student->name }}</td>
        <td class="label">Kelas</td><td class="separator">:</td><td class="bold">{{ $class->name }}</td>
    </tr>
    <tr>
        <td class="label">NIS / NISN</td><td class="separator">:</td><td class="bold">{{ $student->nis }} / {{ $student->nisn }}</td>
        <td class="label">Semester</td><td class="separator">:</td><td class="bold">{{ $semester->semester_number }} ({{ $semester->academicYear->name }})</td>
    </tr>
</table>

<h3>A. Nilai Pengetahuan dan Keterampilan</h3>
<table class="grades">
    <thead>
        <tr>
            <th width="30">No</th>
            <th>Mata Pelajaran</th>
            <th width="40">KKM</th>
            <th width="40">Nilai Harian</th>
            <th width="40">UTS</th>
            <th width="40">UAS</th>
            <th width="40">Nilai Akhir</th>
            <th>Deskripsi Kemajuan Belajar</th>
        </tr>
    </thead>
    <tbody>
        @foreach($grades as $index => $grade)
        <tr>
            <td class="center">{{ $index + 1 }}</td>
            <td>{{ $grade->subject->name }}</td>
            <td class="center">{{ $grade->subject->kkm }}</td>
            <td class="center">{{ $grade->daily_test_avg }}</td>
            <td class="center">{{ $grade->mid_test }}</td>
            <td class="center">{{ $grade->final_test }}</td>
            <td class="center bold">{{ $grade->final_score }}</td>
            <td style="font-size: 9pt;">{{ $grade->description }}</td>
        </tr>
        @endforeach
    </tbody>
</table>

<h3>B. Ketidakhadiran</h3>
<table class="grades" style="width: 300px;">
    <tr>
        <td width="150">Sakit</td>
        <td class="center">{{ $reportCard->attendance_sick }} hari</td>
    </tr>
    <tr>
        <td>Izin</td>
        <td class="center">{{ $reportCard->attendance_permit }} hari</td>
    </tr>
    <tr>
        <td>Tanpa Keterangan</td>
        <td class="center">{{ $reportCard->attendance_absent }} hari</td>
    </tr>
</table>

<h3>C. Catatan Wali Kelas</h3>
<div style="border: 1px solid #000; padding: 10px; min-height: 50px; margin-bottom: 20px;">
    {{ $reportCard->homeroom_comment ?? '-' }}
</div>

<table class="footer">
    <tr>
        <td width="33%">
            Mengetahui,<br>Orang Tua/Wali<br><br><br><br>
            (...........................)
        </td>
        <td width="33%"></td>
        <td width="33%">
            {{ $tenant->address }}, {{ now()->locale('id')->isoFormat('D MMMM Y') }}<br>
            Wali Kelas<br><br><br><br>
            <b>{{ $class->homeroomTeacher->name ?? '...........................' }}</b><br>
            NIP. {{ $class->homeroomTeacher->nip ?? '-' }}
        </td>
    </tr>
    <tr>
        <td colspan="3">
            Mengetahui,<br>Kepala Sekolah<br><br><br><br>
            <b>(...........................)</b><br>
            NIP. ...........................
        </td>
    </tr>
</table>
@endsection
