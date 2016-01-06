Spree::Admin::SearchController.class_eval do
  def known_users
    if exact_match = Spree.user_class.find_by_email(params[:q])
      @users = [exact_match]
    else
      @users = spree_current_user.known_users.ransack({
        :m => 'or',
        :email_start => params[:q],
        :ship_address_firstname_start => params[:q],
        :ship_address_lastname_start => params[:q],
        :bill_address_firstname_start => params[:q],
        :bill_address_lastname_start => params[:q]
        }).result.limit(10)
    end

    render :users
  end


  # Limit users to those who've shopped with one of our enterprises
  def users_with_permissions
    users_without_permissions

    shop_ids = Enterprise.is_distributor.managed_by(spree_current_user).pluck :id
    shop_ids &= [params[:distributor_id].to_i] if params[:distributor_id].present?

    user_ids = Spree::Order.where(distributor_id: shop_ids).pluck(:user_id).uniq

    @users = @users.where id: user_ids

    render json: @users, each_serializer: Api::Admin::UserSerializer
  end
  alias_method_chain :users, :permissions
end
