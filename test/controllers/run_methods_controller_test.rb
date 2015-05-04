require 'test_helper'

class RunMethodsControllerTest < ActionController::TestCase
  setup do
    @run_method = run_methods(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:run_methods)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create run_method" do
    assert_difference('RunMethod.count') do
      post :create, run_method: { description: @run_method.description, name: @run_method.name, run_command: @run_method.run_command }
    end

    assert_redirected_to run_method_path(assigns(:run_method))
  end

  test "should show run_method" do
    get :show, id: @run_method
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @run_method
    assert_response :success
  end

  test "should update run_method" do
    patch :update, id: @run_method, run_method: { description: @run_method.description, name: @run_method.name, run_command: @run_method.run_command }
    assert_redirected_to run_method_path(assigns(:run_method))
  end

  test "should destroy run_method" do
    assert_difference('RunMethod.count', -1) do
      delete :destroy, id: @run_method
    end

    assert_redirected_to run_methods_path
  end
end
