class Import < ActiveRecord::Base
  enum state: %w[
    waiting
    complete
    complete_with_warnings
    failed
    running
    empty
  ].map { |e| [e, e] }.to_h

  attr_accessor :attachments

  after_initialize { self.attachments = [] }

  def add_attachment(file, file_name: nil, content_type: nil)
    attachments << Attachment.new(file, file_name, content_type)
  end
end

Attachment = Struct.new(:file, :file_name, :content_type)
