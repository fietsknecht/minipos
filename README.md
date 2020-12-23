# minipos
<b>Minimal Point-Of-Sale (POS) system for Atari ST in HiSoft BASIC</b>

I am an old bicycle tech (not a software guru) running a small bicycle repair shop.
For several years I used an overpriced and overfeatured commercial POS package under Windows. Having played around with GFA-Basic during the Atari heydays, I decided early 2020 to code something that does what I need and nothing more.
Did an early version in Windows QB64. I wanted it to look like a TOS program, so I used the black Atari font on a white background.
<br>That made me realize nothing beats the real thing. Dug out my old MagiC-PC software (an excellent multi-tasking Atari-ST emulator dating from 1995), only to find out that nor the original GFA-Basic, nor its semi-official successor <a href="http://gfabasic.net">GBE</a>, will run under MagiC. 
However, the (equally excellent) HiSoft BASIC 2.1 from 1991 does work without any problems. That was my weapon of choice to create MINIPOS.TOS.
<br>I have been using the MINIPOS program now for about six months on a daily basis. Definitely not bug-free, but absolutely useable. Maybe it's of some use to someone.

<b>Quick start</b>

The <i>binary</i> directory contains the most recent MINIPOS.TOS. It requires the included directories DATA and RECEIPTS. 
The DATA directory contains sample files needed by the program.
Receipts will be stored in the RECEIPTS directory.
<br>The program should run on any Atari (or Atari emulator) that can display 80x25 chars in 4 colours. You will need an internet connection to send SMS's.

<b>Configuarion</b>

Basically, the program prints receipts in plain ASCII to your default printer. Receipts have a width of 30 characters. Works best with a thermal 58mm POS printer. I use the cheap XP58 from <a href="https://www.xprintertech.com/">Xprinter</a>. Any printer will do if you can set the margins and feed it the right (endless) paper size.
<br>It maintains a customer base and a product base from which you choose what will be printed. The required files are stored in the DATA directory:
<br>CUSTOMER.TXT - name and phone number of your customers
<br>DATABASE.TXT - sales history
<br>HEADER.TXT - the header for your receipts
<br>LAST.TXT - last receipt number
<br>LOGO.TXT - your logo in 5x80 ASCII to be displayed on the home screen
<br>MINIPOS.CFG - tax and language configuration, see the file for details
<br>MTOTAL.TXT - monthly sales totals (summary displayed on home screen)
<br>PARK.TXT - parked sales
<br>PAYMENT.TXT - allowed payment methods
<br>PRODUCT.TXT - name and price (including tax) of your products
<br>REMARK.TXT - your remarks for each sale (if any)
<br>The program only needs a key press to tell it what you want it to do. The available options are shown on the bottom line. That's all there is to it. Try the binary to see how it works. (How's that for a manual?)

<b>SMS</b>

If you put a sale on hold (by choosing <i>Park sale</i> in payment methods), you will have the opportunity to send an SMS to your customer. The SMS text can be configured in MINIPOS.CFG. At this point the SMS will be sent through my pre-configured gateway. You can try it if you like, there are plenty of free sms's left.

<b>Compiling</b>

To compile the source you will need HiSoft BASIC 2.1 for Atari with the NETWORLD library (for talking to an SMTP server to send SMS's).
HiSoft BASIC 2.1 was released in 1991. In 1999 HiSoft released the additional ENCHANT library, which contains NETWORLD.
An excellent online resource for anything related to BASIC on Atari is <a href="https://docs.dev-docs.org/">https://docs.dev-docs.org</a>. Search for HiSoft and you will also find the (scanned) HiSoft BASIC manuals.
<br>Since HiSoft BASIC is similar to QBASIC, it will be relatively easy to port the source to QBASIC (for DOS) or QB64 (for Windows/Linux).

<b>Any questions?</b>

Contact me by reporting an issue. I will get back to you soon.

