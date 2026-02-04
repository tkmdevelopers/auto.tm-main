import { Injectable } from "@nestjs/common";
import * as nodemailer from "nodemailer";

@Injectable()
export class MailService {
  private transporter: nodemailer.Transporter;

  constructor() {
    this.transporter = nodemailer.createTransport({
      service: "gmail",
      auth: {
        user: process.env.EMAIL_USER,
        pass: process.env.EMAIL_PASSWORD,
      },
    });
  }

  async sendOtpEmail(to: string, otp: string): Promise<void> {
    this.transporter.verify((error, success) => {
      if (error) {
        console.error("Nodemailer verification failed:", error);
      } else {
        console.log("Nodemailer is ready to send messages");
      }
    });

    const mailOptions = {
      from: process.env.EMAIL_USER,
      to,
      subject:
        "Служба технической поддержки учетных записей Alpha Motors Dubai",
      text: `Разовый код`,
      html: `Здравствуйте, ${to}!<br>
Мы получили запрос на отправку разового кода для вашей учетной записи Майкрософт.<br><br>
Ваш разовый код: ${otp}<br><br>
Вводите этот код только в приложении. Не делитесь им ни с кем. Мы не будем запрашивать его за пределами официальной платформы.
<br><br>
С уважением,<br>
Служба технической поддержки учетных записей Alpha Motors`,
    };

    await this.transporter.sendMail(mailOptions);
  }
}
