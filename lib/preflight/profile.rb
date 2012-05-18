# coding: utf-8

module Preflight

  # base functionality for all profiles.
  #
  module Profile

    def self.included(base) # :nodoc:
      base.class_eval do
        extend  Preflight::Profile::ClassMethods
        include InstanceMethods
      end
    end

    module ClassMethods
      def profile_name(str)
        @profile_name = str
      end

      def import(profile)
        profile.rules.each do |array|
          rules << array
        end
        profile.errors.each do |array|
          errors << array
        end
        profile.warnings.each do |array|
          warnings << array
        end
      end

      def rule(*args)
        rules << args
      end

      def error(*args)
        errors << args
      end

      def warning(*args)
        warnings << args
      end

      def rules
        @rules ||= []
      end

      def errors
        @errors ||= []
      end

      def warnings
        @warnings ||= []
      end

    end

    module InstanceMethods
      def check(input)
        valid_rules?
        valid_errors?
        valid_warnings?

        if File.file?(input)
          check_filename(input)
        elsif input.is_a?(IO)
          check_io(input)
        else
          raise ArgumentError, "input must be a string with a filename or an IO object"
        end
      end

      def rule(*args)
        instance_rules << args
      end

      def error(*args)
        instance_errors << args
      end

      def warning(*args)
        instance_warnings << args
      end

      private

      def check_filename(filename)
        File.open(filename, "rb") do |file|
          return check_io(file)
        end
      end

      def check_io(io)
        PDF::Reader.open(io) do |reader|
          raise PDF::Reader::EncryptedPDFError if reader.objects.encrypted?
          result = check_pages(reader).merge!(check_hash(reader))
          {
            rules: result[:rules],
            errors: result[:errors],
            warnings: result[:warnings]
          }
        end
      rescue PDF::Reader::EncryptedPDFError
        {
          rules: ["Can't preflight an encrypted PDF"],
          errors: ["Can't preflight an encrypted PDF"],
          warnings: []
        }
      end

      def instance_rules
        @instance_rules ||= []
      end

      def all_rules
        self.class.rules + instance_rules
      end

      def instance_errors
        @instance_errors ||= []
      end

      def all_errors
        self.class.errors + instance_errors
      end

      def instance_warnings
        @instance_warnings ||= []
      end

      def all_warnings
        self.class.warnings + instance_warnings
      end


      def check_hash(reader)
        issues    = {
          rules: [],
          errors: [],
          warnings: []
        }
        issues[:rules] = hash_rules.map { |chk|
          chk.check_hash(reader.objects)
        }.flatten.compact
        issues[:errors] = hash_errors.map { |chk|
          chk.check_hash(reader.objects)
        }.flatten.compact
        issues[:warnings] = hash_warnings.map { |chk|
          chk.check_hash(reader.objects)
        }.flatten.compact

        issues
      rescue PDF::Reader::UnsupportedFeatureError
        {
          rules: [],
          errors: [],
          warnings: []
        }
      end

      def check_pages(reader)
        rules_array = page_rules
        errors_array = page_errors
        warnings_array = page_warnings

        issues    = {
          rules: [],
          errors: [],
          warnings: []
        }

        begin
          reader.pages.each do |page|
            page.walk(*rules_array)
            page.walk(*errors_array)
            page.walk(*warnings_array)
            issues[:rules] += rules_array.map(&:issues).flatten.compact
            issues[:errors] += rules_array.map(&:issues).flatten.compact
            issues[:warnings] += rules_array.map(&:issues).flatten.compact
          end
        rescue PDF::Reader::UnsupportedFeatureError
          nil
        end
        issues
      end

      # ensure all rules follow the prescribed API
      #
      def valid_rules?
        invalid_rules = all_rules.reject { |arr|
          arr.first.instance_methods.map(&:to_sym).include?(:check_hash) ||
          arr.first.instance_methods.map(&:to_sym).include?(:issues)
        }
        if invalid_rules.size > 0
          raise "The following rules are invalid: #{invalid_rules.join(", ")}. Preflight rules MUST respond to either check_hash() or issues()."
        end
      end

      def hash_rules
        all_rules.select { |arr|
          arr.first.instance_methods.map(&:to_sym).include?(:check_hash)
        }.map { |arr|
          klass = arr[0]
          klass.new(*arr[1,10])
        }
      end

      def page_rules
        all_rules.select { |arr|
          arr.first.instance_methods.map(&:to_sym).include?(:issues)
        }.map { |arr|
          klass = arr[0]
          klass.new(*arr[1,10])
        }
      end

      # ensure all errors follow the prescribed API
      #
      def valid_errors?
        invalid_errors = all_errors.reject { |arr|
          arr.first.instance_methods.map(&:to_sym).include?(:check_hash) ||
          arr.first.instance_methods.map(&:to_sym).include?(:issues)
        }
        if invalid_errors.size > 0
          raise "The following errors are invalid: #{invalid_errors.join(", ")}. Preflight errors MUST respond to either check_hash() or issues()."
        end
      end

      def hash_errors
        all_errors.select { |arr|
          arr.first.instance_methods.map(&:to_sym).include?(:check_hash)
        }.map { |arr|
          klass = arr[0]
          klass.new(*arr[1,10])
        }
      end

      def page_errors
        all_errors.select { |arr|
          arr.first.instance_methods.map(&:to_sym).include?(:issues)
        }.map { |arr|
          klass = arr[0]
          klass.new(*arr[1,10])
        }
      end

      # ensure all warnings follow the prescribed API
      #
      def valid_warnings?
        invalid_warnings = all_warnings.reject { |arr|
          arr.first.instance_methods.map(&:to_sym).include?(:check_hash) ||
          arr.first.instance_methods.map(&:to_sym).include?(:issues)
        }
        if invalid_warnings.size > 0
          raise "The following warnings are invalid: #{invalid_warnings.join(", ")}. Preflight warnings MUST respond to either check_hash() or issues()."
        end
      end

      def hash_warnings
        all_warnings.select { |arr|
          arr.first.instance_methods.map(&:to_sym).include?(:check_hash)
        }.map { |arr|
          klass = arr[0]
          klass.new(*arr[1,10])
        }
      end

      def page_warnings
        all_warnings.select { |arr|
          arr.first.instance_methods.map(&:to_sym).include?(:issues)
        }.map { |arr|
          klass = arr[0]
          klass.new(*arr[1,10])
        }
      end
    end
  end
end
