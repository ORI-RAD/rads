require 'test_helper'

class ProjectsControllerTest < ActionController::TestCase

  setup do
    @project = projects(:membership_test)
    @create_params = { project: { name: 'new_project', description: 'new project for testing' } }
    @potential_members = %w{enabled disabled dm}
    @unowned_record = records(:admin)
  end

  def self.should_not_be_a_member_in_the_project()
    should "not be a member in the project" do
      assert !@project.project_memberships.where(user_id: @user.id).exists?, 'user should not be a member in the project'
    end
  end

  def self.should_be_a_member_in_the_project_with_no_roles()
    should "not be a member in the project with no roles" do
      pm = @project.project_memberships.where(user_id: @user.id).first
      assert_not_nil pm
      assert !pm.is_administrator?, 'user should not be an administrator'
      assert !pm.is_data_producer?, 'user should not be a data_producer'
      assert !pm.is_data_consumer?, 'user should not be a data_consumer'
      assert !pm.is_data_manager?, 'user should not be a data_manager'
    end
  end

  def self.should_be_a_data_producer_in_the_project()
    should "not be a data_producer in the project" do
      pm = @project.project_memberships.where(user_id: @user.id).first
      assert_not_nil pm
      assert !pm.is_administrator?, 'user should not be an administrator'
      assert pm.is_data_producer?, 'user should be a data_producer'
      assert !pm.is_data_consumer?, 'user should not be a data_consumer'
      assert !pm.is_data_manager?, 'user should not be a data_manager'
    end
  end

  def self.should_be_a_data_consumer_in_the_project()
    should "be a data_consumer in the project" do
      pm = @project.project_memberships.where(user_id: @user.id).first
      assert_not_nil pm
      assert !pm.is_administrator?, 'user should not be an administrator'
      assert !pm.is_data_producer?, 'user should be a data_producer'
      assert pm.is_data_consumer?, 'user should be a data_consumer'
      assert !pm.is_data_manager?, 'user should not be a data_manager'
    end
  end

  def self.should_be_administrator_in_the_project()
    should "be administrator in the project" do
      pm = @project.project_memberships.where(user_id: @user.id).first
      assert_not_nil pm
      assert pm.is_administrator?, 'user should not be an administrator'
      assert !pm.is_data_producer?, 'user should be a data_producer'
      assert !pm.is_data_consumer?, 'user should not be a data_consumer'
      assert !pm.is_data_manager?, 'user should not be a data_manager'
    end
  end

  def self.should_be_a_data_manager_in_the_project()
    should "be a data_manager in the project" do
      pm = @project.project_memberships.where(user_id: @user.id).first
      assert_not_nil pm
      assert !pm.is_administrator?, 'user should not be an administrator'
      assert !pm.is_data_producer?, 'user should be a data_producer'
      assert !pm.is_data_consumer?, 'user should not be a data_consumer'
      assert pm.is_data_manager?, 'user should be a data_manager'
    end
  end

  def self.should_pass_any_user_tests()
    should "get index" do
      assert_not_nil @user
      get :index
      assert_equal @user.id, @controller.current_user.id
      assert_response :success
      assert_not_nil assigns(:projects)
    end

    should "get show" do
      assert_not_nil @user
      get :show, id: @project
      assert_response :success
      assert_not_nil assigns(:project)
      assert_equal @project.id, assigns(:project).id
    end
  end

  def self.should_pass_any_repository_user_tests()
    should "get new" do
      assert_not_nil @user
      get :new
      assert_equal @user.id, @controller.current_user.id
      assert_response :success
      assert_not_nil assigns(:project)
    end

    should "create a project, get all roles, and be listed as the creator" do
      assert_not_nil @user
      assert_difference('Project.count') do
        assert_difference('ProjectUser.count') do
          post :create, @create_params
          assert_equal @user.id, @controller.current_user.id
          assert_not_nil assigns(:project)
          assert assigns(:project).valid?, "#{ assigns(:project).errors.messages.inspect }"
        end
      end
      assert_not_nil assigns(:project)
      assert_redirected_to project_path(assigns(:project))
      @t_project = Project.find(assigns(:project).id)
      assert_equal @user.id, @t_project.creator_id
      new_pm = @t_project.project_memberships.where(user_id: @user.id).first
      assert_not_nil new_pm
      assert new_pm.is_administrator?, 'user should be administrator in the new project'
      assert new_pm.is_data_producer?, 'user should be data_producer in the new project'
      assert new_pm.is_data_consumer?, 'user should be data_consumer in the new project'
      assert new_pm.is_data_manager?, 'user should be data_manager in the new project'
    end

    should "create a project with project_affiliated_records_attributes" do
      assert_not_nil @user
      assert_not_nil @unaffiliated_records
      assert @unaffiliated_records.length > 0, 'there should be unaffiliated_records'
      @unaffiliated_records.each do |should_not_be_affiliated|
        assert !@project.is_affiliated_record?(should_not_be_affiliated), "#{ should_not_be_affiliated.id } should not be affiliated with #{ @project.id }"
      end
      @create_params[:project][:project_affiliated_records_attributes] = @unaffiliated_records.collect{ |r| { record_id: r.id } }
      assert_difference('Project.count') do
        assert_difference('ProjectUser.count') do
          assert_difference('ProjectAffiliatedRecord.count', @unaffiliated_records.count) do
            post :create, @create_params
            assert_equal @user.id, @controller.current_user.id
            assert_not_nil assigns(:project)
            assert assigns(:project).valid?, "#{ assigns(:project).errors.messages.inspect }"
          end
        end
      end
      assert_not_nil assigns(:project)
      assert_redirected_to project_path(assigns(:project))
      @t_project = Project.find(assigns(:project).id)
      assert_equal @user.id, @t_project.creator_id
      assert @t_project.project_memberships.where(user_id: @user.id).exists?, 'creator should have a new project_membership for the project'
      @unaffiliated_records.each do |should_be_affiliated|
        assert @t_project.is_affiliated_record?(should_be_affiliated), "#{ should_be_affiliated.id } should be affiliated with #{ @t_project.id }"
      end
    end

    should "not create a project with project_affiliated_records_attributes for records that they do not own" do
      assert_not_nil @user
      assert_not_nil @unaffiliated_records
      assert @unaffiliated_records.length > 0, 'there should be unaffiliated_records'
      assert_not_nil @unowned_record
      @unaffiliated_records << @unowned_record
      @unaffiliated_records.each do |should_not_be_affiliated|
        assert !@project.is_affiliated_record?(should_not_be_affiliated), "#{ should_not_be_affiliated.id } should not be affiliated with #{ @project.id }"
      end
      assert @unowned_record.creator_id != @user.id, 'record should not be owned by the user'
      @create_params[:project][:project_affiliated_records_attributes] = @unaffiliated_records.collect{|r| { record_id: r.id } }
      assert_no_difference('Project.count') do
        assert_no_difference('ProjectUser.count') do
          assert_no_difference('ProjectAffiliatedRecord.count') do
            post :create, @create_params
            assert_equal @user.id, @controller.current_user.id
            assert_not_nil assigns(:project)
            assert assigns(:project).valid?, "#{ assigns(:project).errors.messages.inspect }"
          end
        end
      end
      assert_not_nil assigns(:project)
      assert_redirected_to root_path
      @unaffiliated_records.each do |should_not_be_affiliated|
        assert !@project.is_affiliated_record?(should_not_be_affiliated), "#{ should_not_be_affiliated.id } should still not be affiliated with #{ @project.id }"
      end
    end

    should "create a project with project_membership_attributes" do
      assert_not_nil @user
      @create_params[:project][:project_memberships_attributes] = []
      @potential_members.each do |user_type|
        assert !@project.is_member?(users(user_type.to_sym)), "#{ user_type } should not be affiliated with #{ @project.id }"
        @create_params[:project][:project_memberships_attributes] << { user_id: users(user_type.to_sym).id }
      end

      assert_difference('Project.count') do
        assert_difference('ProjectUser.count') do
          assert_difference('ProjectMembership.count', @potential_members.length + 1) do
            post :create, @create_params
            assert_equal @user.id, @controller.current_user.id
            assert_not_nil assigns(:project)
            assert assigns(:project).valid?, "#{ assigns(:project).errors.messages.inspect }"
          end
        end
      end
      assert_not_nil assigns(:project)
      assert_redirected_to project_path(assigns(:project))
      @t_project = Project.find(assigns(:project).id)
      assert_equal @user.id, @t_project.creator_id
      assert @t_project.project_memberships.where(user_id: @user.id).exists?, 'creator should have a new project_membership for the project'
      @potential_members.each do |user_type|
        assert assigns(:project).is_member?(users(user_type.to_sym)), "#{ user_type } should be affiliated with #{ assigns(:project).id }"
      end
    end
  end

  def self.should_pass_any_non_repository_user_tests()
    should "not get :new" do
      assert_not_nil @user
      get :new
      assert_equal @user.id, @controller.current_user.id
      assert_redirected_to root_path()
    end

    should "not create a project" do
      assert_not_nil @user
      assert_no_difference('Project.count') do
        post :create, @create_params
        assert_equal @user.id, @controller.current_user.id
      end
      assert_redirected_to root_path()
    end
  end

  def self.should_pass_project_administrator_tests()
    should 'be able to edit the project' do
      assert_not_nil @user
      assert @project.is_member?(@user), 'user should be a member of the project'
      assert @project.project_memberships.where(user_id: @user.id, is_administrator: true).exists?, 'user should be an administrator in the project'
      get :edit, id: @project
      assert_equal @user.id, @controller.current_user.id
      assert_response :success
    end

    should 'be able to update the project attributes' do
      assert_not_nil @user
      assert @project.is_member?(@user), 'user should be a member of the project'
      assert @project.project_memberships.where(user_id: @user.id, is_administrator: true).exists?, 'user should be an administrator in the project'
      new_description = "NEW DESCRIPTION"
      patch :update, id: @project, project: {description: new_description }
      assert_equal @user.id, @controller.current_user.id
      assert_redirected_to project_path(@project)
      t_p = Project.find(@project.id)
      assert_equal new_description, t_p.description
    end

    should 'be able to update the project to add project_memberships_attributes' do
      assert_not_nil @user
      assert @project.is_member?(@user), 'user should be a member of the project'
      assert @project.project_memberships.where(user_id: @user.id, is_administrator: true).exists?, 'user should be an administrator in the project'
      update_params = {project_memberships_attributes: []}
      @potential_members.each do |user_type|
        assert !@project.is_member?(users(user_type.to_sym)), "#{ user_type } should not be affiliated with #{ @project.id }"
        update_params[:project_memberships_attributes] << { user_id: users(user_type.to_sym).id }
      end

      assert_difference('ProjectMembership.count', @potential_members.length) do
        patch :update, id: @project, project: update_params
        assert_equal @user.id, @controller.current_user.id
      end
      assert_redirected_to project_path(@project)
      t_p = Project.find(@project.id)
      @potential_members.each do |user_type|
        assert t_p.is_member?(users(user_type.to_sym)), "#{ user_type } should now be affiliated with #{ t_p.id }"
      end
    end
  end

  def self.should_pass_not_project_administrator_tests()
    should 'not be able to edit the project' do
      assert_not_nil @user
      get :edit, id: @project
      assert_equal @user.id, @controller.current_user.id
      assert_redirected_to root_path
    end

    should 'not be able to update the project attributes' do
      assert_not_nil @user
      orig_description = @project.description
      new_description = "NEW DESCRIPTION"
      patch :update, id: @project, project: {description: new_description }
      assert_equal @user.id, @controller.current_user.id
      assert_redirected_to root_path
      t_p = Project.find(@project.id)
      assert_equal orig_description, t_p.description
    end

    should 'not be able to update the project to add project_memberships_attributes' do
      assert_not_nil @user
      update_params = {project_memberships_attributes: []}
      @potential_members.each do |user_type|
        assert !@project.is_member?(users(user_type.to_sym)), "#{ user_type } should not be affiliated with #{ @project.id }"
        update_params[:project_memberships_attributes] << { user_id: users(user_type.to_sym).id }
      end

      assert_no_difference('ProjectMembership.count') do
        patch :update, id: @project, project: update_params
        assert_equal @user.id, @controller.current_user.id
      end
      assert_redirected_to root_path
      t_p = Project.find(@project.id)
      @potential_members.each do |user_type|
        assert !t_p.is_member?(users(user_type.to_sym)), "#{ user_type } should still not be affiliated with #{ t_p.id }"
      end
    end
  end

  def self.should_pass_data_producer_tests()
    should 'be able to affiliate multiple records with a project if they are a member with the data_producer role' do
      assert_not_nil @user
      assert_not_nil @unaffiliated_records
      assert @unaffiliated_records.length > 0, 'there should be unaffiliated_records'
      assert @project.project_memberships.where(user_id: @user.id, is_data_producer: true).exists?, 'user should have the data_producer role in the project'
      @unaffiliated_records.each do |should_be_affiliated|
        assert !@project.is_affiliated_record?(should_be_affiliated), "#{ should_be_affiliated.id } should not be affiliated with #{ @project.id }"
      end
      assert_difference('ProjectAffiliatedRecord.count', @unaffiliated_records.length) do
        patch :update, id: @project, project: {
          project_affiliated_records_attributes: @unaffiliated_records.collect {|r|
            { record_id: r.id }
          }
        }
        assert_equal @user.id, @controller.current_user.id
      end
      assert_redirected_to project_path(@project)
      t_p = Project.find(@project.id)
      @unaffiliated_records.each do |should_be_affiliated|
        assert t_p.is_affiliated_record?(should_be_affiliated), "#{ should_be_affiliated.id } should be affiliated with #{ t_p.id }"
      end
    end

    should 'not be able to affiliate multiple records with a project if one of the records is not owned by them' do
      assert_not_nil @user
      assert_not_nil @unaffiliated_records
      assert @unaffiliated_records.length > 0, 'there should be unaffiliated_records'
      assert_not_nil @unowned_record
      @unaffiliated_records << records(:user_unaffiliated)
      assert !@unaffiliated_records.select{|r| r.creator_id != @user.id }.empty?, 'an unaffiliated_record should not be owned by the user'
      @unaffiliated_records.each do |should_be_affiliated|
        assert !@project.is_affiliated_record?(should_be_affiliated), "#{ should_be_affiliated.id } should not be affiliated with #{ @project.id }"
      end
      assert_no_difference('ProjectAffiliatedRecord.count') do
        patch :update, id: @project, project: {
          project_affiliated_records_attributes: @unaffiliated_records.collect {|r|
            { record_id: r.id }
          }
        }
        assert_equal @user.id, @controller.current_user.id
      end
      assert_redirected_to root_path()
      t_p = Project.find(@project.id)
      @unaffiliated_records.each do |should_be_affiliated|
        assert !t_p.is_affiliated_record?(should_be_affiliated), "#{ should_be_affiliated.id } should not be affiliated with #{ t_p.id }"
      end
    end
  end

  def self.should_pass_not_data_producer_tests()
    should 'not be able to affiliate multiple records with a project' do
      assert_not_nil @user
      assert_not_nil @unaffiliated_records
      assert @unaffiliated_records.length > 0, 'there should be unaffiliated_records'
      assert !@project.project_memberships.where(user_id: @user.id, is_data_producer: true).exists?, 'user should not have the data_manager role in the project'
      @unaffiliated_records.each do |should_be_affiliated|
        assert !@project.is_affiliated_record?(should_be_affiliated), "#{ should_be_affiliated.id } should not be affiliated with #{ @project.id }"
      end
      assert_no_difference('ProjectAffiliatedRecord.count') do
        patch :update, id: @project, project: {
          project_affiliated_records_attributes: @unaffiliated_records.collect {|r|
            { record_id: r.id }
          }
        }
        assert_equal @user.id, @controller.current_user.id
      end
      assert_redirected_to root_path
      t_p = Project.find(@project.id)
      @unaffiliated_records.each do |should_be_affiliated|
        assert !t_p.is_affiliated_record?(should_be_affiliated), "#{ should_be_affiliated.id } should still not be affiliated with #{ t_p.id }"
      end
    end
  end

  context 'Not Authenticated' do
    should_not_get :index
    should_not_get :new

    should "not show project" do
      get :show, id: @project
      assert_redirected_to sessions_new_url(:target => project_url(@project))
    end

    should "not create project" do
      assert_no_difference('Project.count') do
        post :create, @create_params
      end
      assert_redirected_to sessions_new_url(:target => projects_url(@create_params))
    end
  end #Not Authenticated

  context 'CoreUser without membership in Project' do
    setup do
      @actual_user = users(:non_admin)
      authenticate_existing_user(@actual_user, true)
      @user = users(:core_user)
      session[:switch_to_user_id] = @user.id
      @unaffiliated_records = @user.records.all.to_a
    end

    should_not_be_a_member_in_the_project
    should_pass_any_non_repository_user_tests
    should_pass_any_user_tests
    should_pass_not_project_administrator_tests
    should_pass_not_data_producer_tests
    
  end #CoreUser without membership in the project

  context 'CoreUser with membership in project but no roles' do
    setup do
      @actual_user = users(:non_admin)
      authenticate_existing_user(@actual_user, true)
      @user = users(:core_user)
      @project.project_memberships.create(user_id: @user.id)
      session[:switch_to_user_id] = @user.id
      @unaffiliated_records = @user.records.all.to_a
    end

    should_be_a_member_in_the_project_with_no_roles
    should_pass_any_non_repository_user_tests
    should_pass_any_user_tests
    should_pass_not_project_administrator_tests
    should_pass_not_data_producer_tests
    
  end #CoreUser with membership in the project but no roles

  context 'CoreUser with the data_producer role in the project' do
    setup do
      @actual_user = users(:non_admin)
      authenticate_existing_user(@actual_user, true)
      @user = users(:p_m_cu_producer)
      session[:switch_to_user_id] = @user.id
      @unaffiliated_records = [ records(:pm_cu_producer_unaffiliated_record), records(:pm_cu_producer_unaffiliated_record2) ]
    end

    should_be_a_data_producer_in_the_project
    should_pass_any_non_repository_user_tests
    should_pass_any_user_tests
    should_pass_not_project_administrator_tests
    should_pass_data_producer_tests
    
  end #CoreUser with the data_producer role in the project

  context 'CoreUser with the data_consumer role in the project' do
    setup do
      @actual_user = users(:non_admin)
      authenticate_existing_user(@actual_user, true)
      @user = users(:core_user)
      @project.project_memberships.create(user_id: @user.id, is_data_consumer: true)
      session[:switch_to_user_id] = @user.id
      @unaffiliated_records = @user.records.all.to_a
    end

    should_be_a_data_consumer_in_the_project
    should_pass_any_non_repository_user_tests
    should_pass_any_user_tests
    should_pass_not_project_administrator_tests
    should_pass_not_data_producer_tests
    
  end #CoreUser with the data_consumer role in the project

  context 'CoreUser with the data_manager role in the project' do
    # this should not happen, but just in case
    setup do
      @actual_user = users(:non_admin)
      authenticate_existing_user(@actual_user, true)
      @user = users(:core_user)
      @project.project_memberships.create(user_id: @user.id, is_data_manager: true)
      session[:switch_to_user_id] = @user.id
      @unaffiliated_records = @user.records.all.to_a
    end

    should_be_a_data_manager_in_the_project
    should_pass_any_non_repository_user_tests
    should_pass_any_user_tests
    should_pass_not_project_administrator_tests
    should_pass_not_data_producer_tests
    
  end #CoreUser with the data_manager role in the project

  context 'CoreUser with the admin role in Project' do
    # this should never happen, but just in case
    setup do
      @actual_user = users(:non_admin)
      authenticate_existing_user(@actual_user, true)
      @user = users(:core_user)
      @project.project_memberships.create(user_id: @user.id, is_administrator: true)
      session[:switch_to_user_id] = @user.id
      @unaffiliated_records = @user.records.all.to_a
    end

    should_be_administrator_in_the_project
    should_pass_not_project_administrator_tests
    
  end #CoreUser with the admin role in the project

  context 'ProjectUser without membership in Project' do
    setup do
      @actual_user = users(:non_admin)
      authenticate_existing_user(@actual_user, true)
      @user = users(:project_user)
      session[:switch_to_user_id] = @user.id
      @unaffiliated_records = @user.records.all.to_a
    end

    should_not_be_a_member_in_the_project
    should_pass_any_non_repository_user_tests
    should_pass_any_user_tests
    should_pass_not_project_administrator_tests
    should_pass_not_data_producer_tests
    
  end #ProjectUser without membership in the project

  context 'ProjectUser with membership in Project but no roles' do
    setup do
      @actual_user = users(:non_admin)
      authenticate_existing_user(@actual_user, true)
      @user = users(:project_user)
      @project.project_memberships.create(user_id: @user.id)
      session[:switch_to_user_id] = @user.id
      @unaffiliated_records = @user.records.all.to_a
    end

    should_be_a_member_in_the_project_with_no_roles
    should_pass_any_non_repository_user_tests
    should_pass_any_user_tests
    should_pass_not_project_administrator_tests
    should_pass_not_data_producer_tests
    
  end #ProjectUser with membership in the project but no roles

  context 'ProjectUser with the data_producer role in the project' do
    setup do
      @actual_user = users(:non_admin)
      authenticate_existing_user(@actual_user, true)
      @user = users(:p_m_pu_producer)
      session[:switch_to_user_id] = @user.id
      @unaffiliated_records = [ records(:pm_cu_producer_unaffiliated_record), records(:pm_cu_producer_unaffiliated_record2) ]
    end

    should_be_a_data_producer_in_the_project
    should_pass_any_non_repository_user_tests
    should_pass_any_user_tests
    should_pass_not_project_administrator_tests
    should_pass_data_producer_tests
    
  end #ProjectUser with the data_producer role in the project

  context 'ProjectUser with the data_consumer role in Project' do
    setup do
      @actual_user = users(:non_admin)
      authenticate_existing_user(@actual_user, true)
      @user = users(:project_user)
      @project.project_memberships.create(user_id: @user.id, is_data_consumer: true)
      session[:switch_to_user_id] = @user.id
      @unaffiliated_records = @user.records.all.to_a
    end

    should_be_a_data_consumer_in_the_project
    should_pass_any_non_repository_user_tests
    should_pass_any_user_tests
    should_pass_not_project_administrator_tests
    should_pass_not_data_producer_tests
    
  end #ProjectUser with the data_consumer role in the project

  context 'ProjectUser with the data_manager role in the project' do
    # this should not happen, but just in case
    setup do
      @actual_user = users(:non_admin)
      authenticate_existing_user(@actual_user, true)
      @user = users(:project_user)
      @project.project_memberships.create(user_id: @user.id, is_data_manager: true)
      session[:switch_to_user_id] = @user.id
      @unaffiliated_records = @user.records.all.to_a
    end

    should_be_a_data_manager_in_the_project
    should_pass_any_non_repository_user_tests
    should_pass_any_user_tests
    should_pass_not_project_administrator_tests
    should_pass_not_data_producer_tests
    
  end #ProjectUser with the data_manager role in the project

  context 'ProjectUser with the administrator role in the project' do
    # this should not happen, but just in case
    setup do
      @actual_user = users(:non_admin)
      authenticate_existing_user(@actual_user, true)
      @user = users(:project_user)
      @project.project_memberships.create(user_id: @user.id, is_administrator: true)
      session[:switch_to_user_id] = @user.id
      @unaffiliated_records = @user.records.all.to_a
    end

    should_be_administrator_in_the_project
    should_pass_any_non_repository_user_tests
    should_pass_any_user_tests
    should_pass_not_project_administrator_tests
    should_pass_not_data_producer_tests
    
  end #ProjectUser with the administrator role in the project

  context 'Administrator RepositoryUser without membership in the project' do
    setup do
      @user = users(:admin)
      authenticate_existing_user(@user, true)
      @unaffiliated_records = @user.records.all.to_a
      @unowned_record = records(:user)
    end

    should_not_be_a_member_in_the_project
    should_pass_any_user_tests
    should_pass_any_repository_user_tests
    should_pass_not_project_administrator_tests
    should_pass_not_data_producer_tests

  end #Administrator RepositoryUser without membership in the project

  context 'Administrator RepositoryUser with membership in the project but no roles' do
    setup do
      @user = users(:admin)
      authenticate_existing_user(@user, true)
      @project.project_memberships.create(user_id: @user.id)
      @unaffiliated_records = @user.records.all.to_a
      @unowned_record = records(:user)
    end

    should_be_a_member_in_the_project_with_no_roles
    should_pass_any_user_tests
    should_pass_any_repository_user_tests
    should_pass_not_project_administrator_tests
    should_pass_not_data_producer_tests

  end #Administrator RepositoryUser with membership in the project but no roles

  context 'Administrator RepositoryUser with the administrator role in the project' do
    setup do
      @user = users(:admin)
      authenticate_existing_user(@user, true)
      @project.project_memberships.create(user_id: @user.id, is_administrator: true)
      @unaffiliated_records = @user.records.all.to_a
      @unowned_record = records(:user)
    end

    should_be_administrator_in_the_project
    should_pass_any_user_tests
    should_pass_any_repository_user_tests
    should_pass_project_administrator_tests
    should_pass_not_data_producer_tests

  end #Administrator RepositoryUser with the administrator role in the project

  context 'Administrator RepositoryUser with the data_consumer role in the project' do
    setup do
      @user = users(:admin)
      authenticate_existing_user(@user, true)
      @project.project_memberships.create(user_id: @user.id, is_data_consumer: true)
      @unaffiliated_records = @user.records.all.to_a
      @unowned_record = records(:user)
    end

    should_be_a_data_consumer_in_the_project
    should_pass_any_user_tests
    should_pass_any_repository_user_tests
    should_pass_not_project_administrator_tests
    should_pass_not_data_producer_tests

  end #Administrator RepositoryUser with the data_consumer role in the project

  context 'Administrator RepositoryUser with the data_producer role in the project' do
    setup do
      @user = users(:admin)
      authenticate_existing_user(@user, true)
      @project.project_memberships.create(user_id: @user.id, is_data_producer: true)
      @unaffiliated_records = @user.records.all.to_a
      @unowned_record = records(:user)
    end

    should_be_a_data_producer_in_the_project
    should_pass_any_user_tests
    should_pass_any_repository_user_tests
    should_pass_not_project_administrator_tests
    should_pass_data_producer_tests

  end #Administrator RepositoryUser with the data_producer role in the project

  context 'Administrator RepositoryUser with the data_manager role in the project' do
    setup do
      @user = users(:admin)
      authenticate_existing_user(@user, true)
      @project.project_memberships.create(user_id: @user.id, is_data_manager: true)
      @unaffiliated_records = @user.records.all.to_a
      @unowned_record = records(:user)
    end

    should_be_a_data_manager_in_the_project
    should_pass_any_user_tests
    should_pass_any_repository_user_tests
    should_pass_not_project_administrator_tests
    should_pass_not_data_producer_tests

  end #Administrator RepositoryUser with the data_manager role in the project

  context 'Non-Administrator RepositoryUser without membership in the project' do
    setup do
      @user = users(:non_admin)
      authenticate_existing_user(@user, true)
      @unaffiliated_records = @user.records.all.to_a
    end

    should_not_be_a_member_in_the_project
    should_pass_any_user_tests
    should_pass_any_repository_user_tests
    should_pass_not_project_administrator_tests
    should_pass_not_data_producer_tests

  end #Non-Admiinistrator RepositoryUser without membership in the project

  context 'Non-Administrator RepositoryUser with membership in the project but no roles' do
    setup do
      @user = users(:p_m_member)
      authenticate_existing_user(@user, true)
      @unaffiliated_records = @user.records.all.to_a
    end

    should_be_a_member_in_the_project_with_no_roles
    should_pass_any_user_tests
    should_pass_any_repository_user_tests
    should_pass_not_project_administrator_tests
    should_pass_not_data_producer_tests

  end #Non-Admiinistrator RepositoryUser with membership in the project but no roles

  context 'Non-Administrator RepositoryUser with the administrator role in the project' do
    setup do
      @user = users(:p_m_administrator)
      authenticate_existing_user(@user, true)
      @unaffiliated_records = @user.records.all.to_a
    end

    should_be_administrator_in_the_project
    should_pass_any_user_tests
    should_pass_any_repository_user_tests
    should_pass_project_administrator_tests
    should_pass_not_data_producer_tests
  end #Non-Admiinistrator RepositoryUser with the administrator role in the project

  context 'Non-Administrator RepositoryUser with the data_consumer role in the project' do
    setup do
      @user = users(:p_m_consumer)
      authenticate_existing_user(@user, true)
      @unaffiliated_records = @user.records.all.to_a
    end

    should_be_a_data_consumer_in_the_project
    should_pass_any_user_tests
    should_pass_any_repository_user_tests
    should_pass_not_project_administrator_tests
    should_pass_not_data_producer_tests

  end #Non-Admiinistrator RepositoryUser with the data_consumer role in the project

  context 'Non-Administrator RepositoryUser with the data_producer role in the project' do
    setup do
      @user = users(:p_m_producer)
      authenticate_existing_user(@user, true)
      @unaffiliated_records = [ records(:pm_producer_unaffiliated_record), records(:pm_producer_unaffiliated_record2) ]
    end

    should_be_a_data_producer_in_the_project
    should_pass_any_user_tests
    should_pass_any_repository_user_tests
    should_pass_not_project_administrator_tests
    should_pass_data_producer_tests

  end #Non-Admiinistrator RepositoryUser with the data_producer role in the project

  context 'Non-Administrator RepositoryUser with the data_manager role in the project' do
    setup do
      @user = users(:p_m_dmanager)
      authenticate_existing_user(@user, true)
      @unaffiliated_records = @user.records.all.to_a
    end

    should_be_a_data_manager_in_the_project
    should_pass_any_user_tests
    should_pass_any_repository_user_tests
    should_pass_not_project_administrator_tests
    should_pass_not_data_producer_tests

  end #Non-Administrator RepositoryUser with the data_manager role in the project

  context 'Potential Memberships' do
    setup do
      @user = users(:non_admin)
      authenticate_existing_user(@user, true)
    end

    should "be provided to RepositoryUser in get :new" do
      get :new
      assert_response :success
      assert_not_nil assigns(:project)

      assert_not_nil assigns(:potential_members), 'potential_members should be set'
      assert !assigns(:potential_members).empty?, 'should have potential_members'
      %w{enabled disabled admin dm core_user project_user}.each do |user_type|
        assert assigns(:potential_members).include?(users(user_type.to_sym)), "should include #{user_type} in potential_members"
      end
      assert !assigns(:potential_members).include?(@user), 'should not include current user in potential_members'
    end

  end # Potential Members

  context 'Unaffiliated Records' do
    setup do
      @user = users(:non_admin)
      authenticate_existing_user(@user, true)
    end

    should 'be provided to RepositoryUser in get :new' do
      get :new
      assert_response :success
      assert_not_nil assigns(:project)

      assert_not_nil assigns(:unaffiliated_records)
      assert !assigns(:unaffiliated_records).empty?, 'should have unaffiliated_records'
      assert assigns(:unaffiliated_records).include?(records(:user_unaffiliated)), 'should include user_unaffiliated in unaffiliated_records'
      assert !assigns(:unaffiliated_records).include?(records(:admin)), 'should not include another users record in unaffiliated_records'

      assert_equal assigns(:project).project_affiliated_records.length, assigns(:unaffiliated_records).length    end
  end #Unaffiliated Records
end
