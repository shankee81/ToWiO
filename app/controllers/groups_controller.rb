class GroupsController < BaseController
  layout 'darkswarm'

  before_filter :load_group, only: %i(show embed)

  def index
    @groups = EnterpriseGroup.on_front_page.by_position
  end

  def show
  end

  def embed
    truthy_values = ['y', 'yes', '1', 't', 'true']

    @hide_header = !truthy_values.include?((params[:header]||'').downcase)

    render :show, layout: 'embedded'
  end


  private

  def load_group
    @group = EnterpriseGroup.find_by_permalink(params[:id]) || EnterpriseGroup.find(params[:id])
  end

end
