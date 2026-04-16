<?php

namespace App\Mail;

use Illuminate\Mail\Mailable;
use Illuminate\Mail\Mailables\Content;
use Illuminate\Mail\Mailables\Envelope;
use Illuminate\Queue\SerializesModels;

class PasswordResetMail extends Mailable
{
    use SerializesModels;

    public function __construct(
        public string $userName,
        public string $resetUrl
    ) {}

    public function envelope(): Envelope
    {
        return new Envelope(subject: 'Recuperación de contraseña — Yoltec');
    }

    public function content(): Content
    {
        return new Content(view: 'emails.password-reset');
    }

    public function attachments(): array
    {
        return [];
    }
}
