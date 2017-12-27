module WorkerTools
  module RocketchatErrorNotifier
    def with_rocketchat_error_notifier(&block)
      block.yield
    rescue StandardError => e
      rocketchat_error_notify(e) if rocketchat_error_notifier_enabled
      raise
    end

    def rocketchat_error_notifier_enabled
      Rails.env.production?
    end

    def rocketchat_error_notifier_emoji
      ':red_circle:'
    end

    def rocketchat_error_notifier_receivers
      # Ex: '@all'
    end

    def rocketchat_error_notifier_event
      'Worker Error Notifier'
    end

    def rocketchat_error_notifier_title
      # Example with a link:
      #
      # For urls a default_url_options[:host] might be necessary.
      # In this example I just copy it from existing action_mailer defaults.
      #
      # import = rocketchat_error_notifier_model
      # host = Rails.application.config.action_mailer.default_url_options[:host]
      # url = Rails.application.routes.url_helpers.import_url(import, host: host, protocol: :https)
      # kind = I18n.t(import.kind, scope: 'import.kinds')
      # text = "##{import.id} *#{kind}*"
      # "[#{text}](#{url})"
      klass = model.class.model_name.human
      kind = I18n.t("activerecord.attributes.#{model.class.name.underscore}.kinds.#{model.kind}")
      "#{klass} #{kind} ##{model.id}"
    end

    def rocketchat_error_notifier_error_details(error)
      details = "#{error.class}: #{error.message}\n"
      details << error.backtrace[0..10].join("\n")
    end

    def rocketchat_error_notifier_message
      message = []
      message << rocketchat_error_notifier_receivers
      message << rocketchat_error_notifier_title
      message.compact.join(' - ')
    end

    def rocketchat_error_notifier_attachment(error)
      { collapsed: true, title: 'Error', text: rocketchat_error_notifier_error_details(error) }
    end

    def rocketchat_error_notify(error)
      RocketChatNotifier.notify(
        rocketchat_error_notifier_message,
        emoji: rocketchat_error_notifier_emoji,
        event: "#{rocketchat_error_notifier_event} (#{Rails.env})",
        attachment: rocketchat_error_notifier_attachment(error)
      )
    end
  end
end
