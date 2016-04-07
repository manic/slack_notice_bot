# -*- encoding : utf-8 -*-
require 'spec_helper'

describe SlackBot do
  context 'cfg' do
    Given(:obj) { SlackBot.new }
    Then { obj.channel_id == 'C0EE7929K' }
    And { obj.nickname('U054KRJP5') == 'manic' }
  end
end
