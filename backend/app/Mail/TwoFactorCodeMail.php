<?php

namespace App\Mail;

use Illuminate\Mail\Mailable;
use Illuminate\Mail\Mailables\Content;
use Illuminate\Mail\Mailables\Envelope;
use Illuminate\Queue\SerializesModels;

class TwoFactorCodeMail extends Mailable
{
    use SerializesModels;

    public function __construct(
        public string $code,
        public string $userName
    ) {}

    public function envelope(): Envelope
    {
        return new Envelope(subject: 'Tu código de verificación - Yoltec');
    }

    public function content(): Content
    {
        return new Content(view: 'emails.two-factor-code');
    }

    public function attachments(): array
    {
        return [];
    }
}
