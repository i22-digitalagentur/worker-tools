require 'slack-notifier'

module WorkerTools
  module SlackErrorNotifier
    def with_wrapper_slack_error_notifier(&block)
      block.yield
    rescue StandardError => e
      slack_error_notify(e) if slack_error_notifier_enabled
      raise
    end

    def slack_error_notifier_enabled
      Rails.env.production?
    end

    def slack_error_notifier_emoji
      ':red_circle:'
    end

    def slack_error_notifier_channel
      return SLACK_NOTIFIER_CHANNEL if defined?(SLACK_NOTIFIER_CHANNEL)

      raise 'Define slack_error_notifier_channel or set SLACK_NOTIFIER_CHANNEL in an initializer'
    end

    def slack_error_notifier_webhook
      return SLACK_NOTIFIER_WEBHOOK if defined?(SLACK_NOTIFIER_WEBHOOK)

      raise 'Define slack_error_notifier_webhook or set SLACK_NOTIFIER_WEBHOOK in an initializer'
    end

    def slack_error_notifier_username
      'Notifier'
    end

    def slack_error_notifier_receivers
      # Ex: '@all'
    end

    def slack_error_notifier_attachments_color
      # good, warning, danger, hex color
      'danger'
    end

    def slack_error_notifier_title
      # Example with a link:
      #
      # For urls a default_url_options[:host] might be necessary.
      # In this example I just copy it from existing action_mailer defaults.
      #
      # import = slack_error_notifier_model
      # host = Rails.application.config.action_mailer.default_url_options[:host]
      # url = Rails.application.routes.url_helpers.import_url(import, host: host, protocol: :https)
      # kind = I18n.t(import.kind, scope: 'import.kinds')
      # text = "##{import.id} *#{kind}*"
      # "[#{text}](#{url})"
      klass = model.class.model_name.human
      kind = I18n.t("activerecord.attributes.#{model.class.name.underscore}.kinds.#{model.kind}")
      "#{klass} #{kind} ##{model.id}"
    end

    def slack_error_notifier_error_details(error)
      error.backtrace[0..2].join("\n")
    end

    def slack_error_notifier_message
      message = []
      message << slack_error_notifier_receivers
      message << slack_error_notifier_title
      message.compact.join(' - ')
    end

    def slack_error_notifier_attachments(error)
      [
        { color: slack_error_notifier_attachments_color, fields: slack_error_notifier_attachments_fields },
        {
          title: [error.class, error.message].join(' : '),
          color: slack_error_notifier_attachments_color,
          text: slack_error_notifier_error_details(error)
        }
      ]
    end

    def slack_error_notifier_attachments_fields
      [
        { title: 'Application', value: Rails.application.class.parent_name, short: true },
        { title: 'Environment', value: Rails.env, short: true }
      ]
    end

    def slack_error_notifier
      Slack::Notifier.new(slack_error_notifier_webhook)
    end

    def slack_error_notify(error)
      slack_error_notifier.post(
        username: slack_error_notifier_username,
        channel: slack_error_notifier_channel,
        icon_emoji: slack_error_notifier_emoji,
        text: "*#{slack_error_notifier_message}*",
        attachments: slack_error_notifier_attachments(error)
      )
    end
  end
end
