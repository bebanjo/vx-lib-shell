require 'net/ssh'
require 'timeout'

module Vx
  module Lib
    module Spawn
      class SSH

        class << self
          def open(host, user, options = {}, &block)
            ::Net::SSH.start(host, user, {
              paranoid:      false
            }.merge(options)) do |ssh|
              yield new(ssh)
            end
          end
        end

        attr_reader :host, :user, :options, :connection

        def initialize(ssh)
          @connection = ssh
        end

        def spawn(command, options = {}, &block)
          exit_code     = nil
          timeout       = Spawn::Timeout.new options.delete(:timeout)
          read_timeout  = Spawn::ReadTimeout.new options.delete(:read_timeout)

          channel = spawn_channel command, read_timeout, options, &block

          channel.on_request("exit-status") do |_,data|
            exit_code = data.read_long
          end

          channel.on_request("exit-signal") do |_,data|
            exit_code = data.read_long * -1
          end

          pool channel, timeout, read_timeout

          compute_exit_code command, exit_code, timeout, read_timeout
        end

        private

          def request_pty(channel, options)
            if options[:pty]
              channel.request_pty do |_, pty_status|
                raise StandardError, "could not obtain pty" unless pty_status
                yield if block_given?
              end
            else
              yield if block_given?
            end
          end

          def pool(channel, timeout, read_timeout)
            @connection.loop Spawn.pool_interval do
              if read_timeout.happened? || timeout.happened?
                false
              else
                channel.active?
              end
            end
          end

          def compute_exit_code(command, exit_code, timeout, read_timeout)
            case
            when read_timeout.happened?
              raise Spawn::ReadTimeoutError.new command, read_timeout.value
            when timeout.happened?
              raise Spawn::TimeoutError.new command, timeout.value
            else
              exit_code || -1 # nil exit_code means that the process is killed
            end
          end

          def spawn_channel(command, read_timeout, options, &block)
            @connection.open_channel do |channel|

              request_pty channel, options do

                read_timeout.reset

                channel.exec command do |_, success|

                  unless success
                    yield "FAILED: couldn't execute command (ssh.channel.exec)\n" if block_given?
                  end

                  channel.on_data do |_, data|
                    yield data if block_given?
                    read_timeout.reset
                  end

                  channel.on_extended_data do |_, _, data|
                    yield data if block_given?
                    read_timeout.reset
                  end

                  if i = options[:stdin]
                    channel.send_data i.read
                    channel.eof!
                  end

                end
              end
            end

          end

      end
    end
  end
end
