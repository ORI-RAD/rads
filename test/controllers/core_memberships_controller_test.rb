require 'test_helper'

class CoreMembershipsControllerTest < ActionController::TestCase

  setup do
    @core = cores(:one)
    @core_membership = @core.core_memberships.first
    @create_params = {core_id: @core.id, core_membership: { repository_user_id: users(:admin).id }}
  end

  context 'CoreUser' do
    setup do
      @user = users(:non_admin)
      authenticate_user(@user)
      @puppet = users(:core_user)
      session[:switch_to_user_id] = @puppet.id
    end

    should "not get :index" do
      get :index, core_id: @core
      assert_access_controlled_action
      assert_redirected_to root_path()
    end

    should "not get :new" do
      get :new, core_id: @core
      assert_access_controlled_action
      assert_redirected_to root_path()
    end

    should "not show core_membership" do
      get :show, core_id: @core, id: @core_membership
      assert_access_controlled_action
      assert_redirected_to root_path()
    end

    should "not create core_membership" do
      assert_no_difference('CoreMembership.count') do
        post :create, @create_params
        assert_access_controlled_action
      end
      assert_redirected_to root_path()
    end

    should "not destroy core_membership" do
      assert_no_difference('CoreMembership.count') do
        delete :destroy, core_id: @core, id: @core_membership
        assert_access_controlled_action
      end
      assert_redirected_to root_path()
    end
  end #CoreUser

  context 'ProjectUser' do
    setup do
      @user = users(:non_admin)
      authenticate_user(@user)
      @puppet = users(:project_user)
      session[:switch_to_user_id] = @puppet.id
    end

    should "not get :index" do
      get :index, core_id: @core
      assert_access_controlled_action
      assert_redirected_to root_path()
    end

    should "not get :new" do
      get :new, core_id: @core
      assert_access_controlled_action
      assert_redirected_to root_path()
    end

    should "not show core_membership" do
      get :show, core_id: @core, id: @core_membership
      assert_access_controlled_action
      assert_redirected_to root_path()
    end

    should "not create core_membership" do
      assert_no_difference('CoreMembership.count') do
        post :create, @create_params
        assert_access_controlled_action
      end
      assert_redirected_to root_path()
    end

    should "not destroy core_membership" do
      assert_no_difference('CoreMembership.count') do
        delete :destroy, core_id: @core, id: @core_membership
        assert_access_controlled_action
      end
      assert_redirected_to root_path()
    end
  end #ProjectUser

  context 'Non Core Member' do
    setup do
      @user = users(:admin)
      authenticate_user(@user)
    end

    should "not get :index" do
      get :index, core_id: @core
      assert_access_controlled_action
      assert_redirected_to root_path()
    end

    should "not get :new" do
      get :new, core_id: @core
      assert_access_controlled_action
      assert_redirected_to root_path()
    end

    should "not show core_membership" do
      get :show, core_id: @core, id: @core_membership
      assert_access_controlled_action
      assert_redirected_to root_path()
    end

    should "not create core_membership" do
      assert !@core.is_member?(@user), 'user is a member of the core'
      assert_no_difference('CoreMembership.count') do
        post :create, @create_params
        assert_access_controlled_action
      end
      assert_redirected_to root_path()
    end

    should "not destroy core_membership" do
      assert_no_difference('CoreMembership.count') do
        delete :destroy, core_id: @core, id: @core_membership
        assert_access_controlled_action
      end
      assert_redirected_to root_path()
    end
  end #Non Core Member

  context 'Core Member' do
    setup do
      @user = users(:non_admin)
      authenticate_user(@user)
    end

    should "get :index" do
      get :index, core_id: @core
      assert_access_controlled_action
      assert_response :success
    end

    should "get :new" do
      get :new, core_id: @core
      assert_access_controlled_action
      assert_response :success
      assert_not_nil assigns(:core_membership)
      assert_equal @core.id, assigns(:core_membership).core_id
      assert @core.core_memberships.count > 0, 'there should be at least one core_membership'
      assert_not_nil assigns(:non_members)
      assert assigns(:non_members).include?(users(:admin)), 'admin should be in the list of non_members'
      assert !assigns(:non_members).include?(users(:non_admin)), 'non_admin should not be in the list of non_members'
    end

    should "show core_membership" do
      get :show, core_id: @core, id: @core_membership
      assert_access_controlled_action
      assert_response :success
    end

    should "create core_membership" do
      assert_difference('CoreMembership.count') do
        post :create, @create_params
        assert_access_controlled_action
        assert_not_nil assigns(:core_membership)
        assert assigns(:core_membership).errors.messages.empty?, "#{ assigns(:core_membership).errors.messages.inspect }"
        assert assigns(:core_membership).valid?, "#{ assigns(:core_membership).errors.inspect }"
      end
      assert_redirected_to core_core_membership_url(@core, assigns(:core_membership))
    end

    should "destroy core_membership" do
      assert_difference('CoreMembership.count', -1) do
        delete :destroy, core_id: @core, id: @core_membership
        assert_access_controlled_action
      end
      assert_redirected_to core_core_memberships_url(@core)
    end

  end #Core Member
end
