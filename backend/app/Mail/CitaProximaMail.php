<?php

namespace App\Mail;

use Illuminate\Mail\Mailable;
use Illuminate\Mail\Mailables\Content;
use Illuminate\Mail\Mailables\Envelope;
use Illuminate\Queue\SerializesModels;

class CitaProximaMail extends Mailable
{
    use SerializesModels;

    public function __construct(
        public string $nombreAlumno,
        public string $fechaCita,
        public string $horaCita,
        public string $motivo
    ) {}

    public function envelope(): Envelope
    {
        return new Envelope(subject: 'Recordatorio de cita médica - Yoltec');
    }

    public function content(): Content
    {
        return new Content(view: 'emails.cita-proxima');
    }

    public function attachments(): array
    {
        return [];
    }
}
