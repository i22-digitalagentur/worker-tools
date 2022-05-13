# WorkerTools

[![Build Status][build-badge]][build-url]
[![MIT License][license-shield]][license-url]
[![Release][release-shield]][release-url]
![Maintenance][maintained-shield]

<br>

<details open="open">
  <summary>Table of Contents</summary>
  <ol>
    <li>
      <a href="#about-the-project">About The Project</a>
    </li>
    <li>
      <a href="#installation">Installation</a>
    </li>
    <li><a href="#conventions">Conventions</a></li>
    <li><a href="#module-basics">Module 'Basics'</a></li>
    <li><a href="#module-recorder">Module 'Recorder'</a></li>
    <li><a href="#module-slackerrornotifier">Module 'SlackErrorNotifier'</a></li>
    <li><a href="#wrappers">Wrappers</a></li>
    <li><a href="#module-notes">Module 'Notes'</a></li>
    <li><a href="#requirements">Requirements</a></li>
    <li><a href="#contributing">Contributing</a></li>
    <li><a href="#license">License</a></li>
    <li><a href="#acknowledgement">Acknowledgement</a></li>
  </ol>
</details>

## About The Project

WorkerTools is a collection of modules meant to speed up how we write background tasks following a few basic patterns. The structure of plain independent modules with limited abstraction allows to define and override a few methods according to your needs without requiring a deep investment in the library.

These modules provide some features and conventions to address the following points with little configuration on your part:

- How to save the state the task.
- How to save notes relevant to the admins / customers.
- How to log the details
- How to handle exceptions and send notifications
- How to process CSV files (as input and output)
- How to process XLXS files (as input, output coming next)
- How to set options

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'worker_tools'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install worker_tools

## Conventions

Most of the modules require an ActiveRecord model to keep track of the state, notes, and files related to the job. The class of this model is typically an Import, Export, Report.. or something more generic like a JobEntry.

An example of this model for an Import using Paperclip would be something like this:

```ruby
class Import < ApplicationRecord
  enum state: { waiting: 0, complete: 1, failed: 2 }
  enum kind: { foo: 0, bar: 1 }

  has_attached_file :attachment

  validates :kind, presence: true
  validates :state, presence: true
  end
```

The state `complete` and `failed` are used by the modules. Both `state` and `kind` could be an enum or just a string field.  Whether you have one, none or many attachments, and which library you use to handle it's up to you.

In this case the migration would be something like this:

```ruby
  def change
    create_table :imports do |t|
      t.integer :kind, null: false
      t.integer :state, default: 0, null: false
      t.json :notes, default: []
      t.json  :options, default: {}
      t.json :meta, default: {}

      t.string :attachment_file_name
      t.integer :attachment_file_size
      t.string :attachment_content_type

      t.timestamps
    end
 ```

## Module 'Basics'

the [basics module](/lib/worker_tools/basics.rb) takes care of finding or creating the model, marking it as completed or failed, and calling any flow control wrappers around `run` that had been specified. (See wrappers)

A simple example would be as follows:

```ruby
class MyImporter
  include WorkerTools::Basic
  wrappers :basics

  def model_class
    Import
  end

  def model_kind
    'foo'
  end

  def run
    # do stuff
  end
end
```

The basics module contains a `perform` method, which is the usual entry point for ApplicationJob and Sidekiq. It can receive the id of the model, the model instance, or nothing, in which case it will attempt to create this model on its own.


## Module 'Recorder'

Provides some methods to manage a log and the `notes` field of the model. The main methods are `add_info`, `add_log`, and `record` (which both logs and appends the message to the notes field). See all methods in [recorder](/lib/worker_tools/recorder.rb)

This module has a _recoder_ wrapper that will register the exception details into the log and notes field in case of error:

```ruby
class MyImporter
  include WorkerTools::Basic
  wrappers :basics, :recorder
  # ...
end
```

If you only want the logger functions, without worrying about persisting a model, you can use the `logger` wrapper and include the module as a stand alone component (without the basics module), like this:

```ruby
  class StandAloneWithLogging
    include WorkerTools::Recorder

    def perform
      with_wrapper_logger do
        # do stuff
      end
    end
  end
```

## Module SlackErrorNotifier

Provides a Slack error notifier wrapper. To do this, you need to define SLACK_NOTIFIER_WEBHOOK as well as SLACK_NOTIFIER_CHANNEL. Then you need to include the SlackErrorNotifier module in your class and append slack_error_notifier to your wrappers. Below you can see an example. 

```ruby
  class MyImporter
    include WorkerTools::SlackErrorNotifier

    wrappers :slack_error_notifier

    def perform
      with_wrapper_logger do
        # do stuff
      end
    end
  end
```

See all methods in [slack_error_notifier](/lib/worker_tools/slack_error_notifier.rb)

## Module CSV Input

See all methods in [csv_input](/lib/worker_tools/csv_input.rb)

## Module CSV Output

See all methods in [csv_output](/lib/worker_tools/csv_output.rb)

## Module XLSX Input

See all methods in [xlsx_input](/lib/worker_tools/xlsx_input.rb)


## Wrappers

In the [basics module](/lib/worker_tools/basics.rb), `perform` calls your custom method `run` to do the actual work of the task, and wraps it around any methods expecting a block that you might have had defined using `wrappers`.  That gives us a systematic way to add logic depending on the output of `run` and any exceptions that might arise, such as logging the error and context, sending a chat notification, retrying under some circumstances, etc.

The following code

```ruby
class MyImporter
  include WorkerTools::Basic
  wrappers :basics

  def run
    # do stuff
  end

  # ..
end
```

is internally handled as

```ruby
def perform(model_id)
  # set model
  with_wrapper_basics do
    run
  end
end
```

where this wrapper method looks like

```ruby
def with_wrapper_basics(&block)
  block.yield # calls run
  # marks the import as complete
  rescue Exception
  # marks the import as failed
  raise
end
```

if we also add a wrapper to send notifications, such as
`wrappers :basics, :rocketchat_error_notifier`

the resulting nested calls would look like

```ruby
def perform(model_id)
  # set model
  with_wrapper_basics do
    with_wrapper_rocketchat_error_notifier do
      run
    end
  end
end
```

## Counters

There is a counter wrapper that you can use to add custom counters to the meta attribute. To do this, you need to complete the following tasks:
- include WorkerTools::Counters to your class
- add :counters to the wrappers method props
- call counters method with your custom counters
You can see an example below. After that, you can access your custom counters via the meta attribute.

```ruby
class MyImporter
  include WorkerTools::Counters
  wrappers :counters
  counters :foo, :bar

  def run
    example_foo_counter_methods
  end

  def example_foo_counter_methods
    self.foo = 0

    10.times { increment_foo }

    puts foo # foo == 10
  end
  
  # ..
end
```

## Benchmark

There is a benchmark wrapper that you can use to record the benchmark. The only thing you need to do is to include the benchmark module and append the name to the wrapper array. Below you can see an example of the integration.

```ruby
class MyImporter
  include WorkerTools::CustomBenchmark
  wrappers :benchmark

  def run
    # do stuff
  end

  # ..
end
```

## Module 'Notes'

If you use ActiveRecord you may need to modify the serializer as well as deserializer from the note attribute. After that you can easily serialize hashes and array of hashes with indifferent access. For that purpose the gem provides two utility methods. (HashWithIndifferentAccessType, SerializedArrayType). There is an example of how you can use it.

```ruby
  class ServiceTask < ApplicationRecord

    attribute :notes, SerializedArrayType.new(type: HashWithIndifferentAccessType.new)
  end
```

See all methods in [utils](/lib/worker_tools/utils)

## Requirements

 - ruby > 2.3.1

## Contributing
Contributions are what make the open source community such an amazing place to be learn, inspire, and create. Any contributions you make are **greatly appreciated**.

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/new_feature`)
3. Commit your Changes (`git commit -m 'feat: Add new feature'`)
4. Push to the Branch (`git push origin feature/new_feature`)
5. Open a Pull Request

## License

The gem is available under the MIT License. See `LICENSE` for more information.

## Acknowledgement

* [Img Shields](https://shields.io)




<!--shield-styles-->
[build-badge]: https://travis-ci.org/i22-digitalagentur/worker-tools.svg?branch=master
[build-url]: https://travis-ci.org/i22-digitalagentur/worker-tools
[maintained-shield]: https://img.shields.io/badge/Maintained%3F-yes-green.svg?style=flat
[release-shield]: https://img.shields.io/github/release/i22-digitalagentur/coverage-badge-creator.svg?style=flat
[release-url]: https://GitHub.com/i22-digitalagentur/worker-tools/releases/
[license-shield]: https://img.shields.io/badge/License-MIT-yellow.svg?style=flat
[license-url]: https://github.com/i22-digitalagentur/worker-tools/blob/master/LICENSE
