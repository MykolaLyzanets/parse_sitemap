# frozen_string_literal: true

require 'rexml/parsers/pullparser'
require 'stringio'

module Sitemaps
  class XmlLocStreamer
    def self.each_loc(xml)
      return enum_for(:each_loc) unless block_given?

      pull = REXML::Parsers::PullParser.new(StringIO.new(xml))
      stack = []

      while pull.has_next?
        event = pull.pull
        case event.event_type
        when :start_element
          stack << local_name(event[0])
        when :end_element
          name = local_name(event[0])
          stack.pop if stack.last == name
        when :text
          text = event[0]
          next if text.strip.empty?
          next unless stack.last == 'loc'

          parent = stack[-2]
          yield parent, text.strip if parent
        end
      end
    end

    def self.local_name(tag)
      tag.to_s.split(':', 2).last
    end
  end
end
