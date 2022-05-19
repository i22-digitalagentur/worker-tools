require 'test_helper'

describe WorkerTools::SlackErrorNotifier do
  class ImporterWithSlackErrorNotifier
    include WorkerTools::Basics
    include WorkerTools::SlackErrorNotifier

    wrappers :basics, :slack_error_notifier

    def model_class
      Import
    end

    def model_kind
      'foo/test'
    end

    def run; end
  end

  let(:worker) { ImporterWithSlackErrorNotifier.new }

  describe '#slack_error_notify' do
    it 'is called if enabled and the error if notifiable' do
      worker.stubs(:run).raises(StandardError)
      worker.stubs(:slack_error_notifier_enabled).returns(true)
      worker.stubs(:slack_error_notifiable?).returns(true)
      worker.expects(:slack_error_notify)
      assert_raises(StandardError) { worker.perform }
    end

    it 'is not called if disabled' do
      worker.stubs(:run).raises(StandardError)
      worker.stubs(:slack_error_notifier_enabled).returns(false)
      worker.stubs(:slack_error_notifiable?).returns(true)
      worker.expects(:slack_error_notify).never
      assert_raises(StandardError) { worker.perform }
    end

    it 'is not called if the error is not notifiable ' do
      worker.stubs(:run).raises(StandardError)
      worker.stubs(:slack_error_notifier_enabled).returns(true)
      worker.stubs(:slack_error_notifiable?).returns(false)
      worker.expects(:slack_error_notify).never
      assert_raises(StandardError) { worker.perform }
    end
  end
end
