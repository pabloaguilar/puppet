require 'spec_helper'
describe 'omegaup' do

  context 'with defaults for all parameters' do
    it { should contain_class('omegaup') }
  end
end
