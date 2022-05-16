class Import < ActiveRecord::Base
  enum state: { waiting: 0, complete: 1, failed: 2, complete_with_warnings: 3 }

  attr_accessor :attachments

  after_initialize { self.attachments = [] }

  def add_attachment(file, file_name: nil, content_type: nil)
    attachments << Attachment.new(file, file_name, content_type)
  end
end

Attachment = Struct.new(:file, :file_name, :content_type)
