class EventMailer < ActionMailer::Base
  default from: 'Le BôBar <bobar.tdb@gmail.com>'
  default reply_to: 'Le BôBar <bobar@binets.polytechnique.fr>'
  default bcc: 'bobar.tdb@gmail.com'

  def submit(event, binet, submitter, filepath)
    @event = event
    @binet = binet
    @submitter = submitter
    @transactions = event.transactions
    attachments[File.basename(filepath)] = File.read(filepath)
    mail(
      to: 'bobar@binets.polytechnique.fr',
      cc: submitter.mail,
      subject: "L'évènement #{@event.name} a été soumis pour paiement",
    )
  end
end
