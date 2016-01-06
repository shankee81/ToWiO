require 'spec_helper'

describe Spree::Admin::SearchController do
  include AuthenticationWorkflow

  context "Distributor Enterprise User" do
    let!(:enterprise) { create(:enterprise, owner: owner, users: [owner, manager]) }
    let!(:owner) { create_enterprise_user( email: "test1@email.com" ) }
    let!(:manager) { create_enterprise_user( email: "test2@email.com" ) }
    let!(:random) { create_enterprise_user( email: "test3@email.com" ) }
    before { login_as_enterprise_user [enterprise] }

    describe "searching for users" do
      let!(:customer) { create(:user, email: "customer@example.com") }
      let!(:non_customer) { create(:user, email: "noncustomer@example.com") }
      let!(:order) { create(:order, state: 'complete', user: customer, distributor: enterprise) }

      it "shows users who have ordered through an enterprise I own/manage" do
        spree_get :users, q: "customer"
        expect(assigns(:users)).to include customer
      end

      it "does not show users who aren't associated" do
        spree_get :users, q: "noncustomer"
        expect(assigns(:users)).to_not include non_customer
      end

      describe "when I specify a shop" do
        let(:enterprise2) { create(:enterprise) }

        it "limits users to those who have ordered through that shop" do
          spree_get :users, q: "customer", distributor_id: enterprise.id.to_s
          expect(assigns(:users)).to include customer
        end

        it "does not return customers who have not ordered through that shop" do
          spree_get :users, q: "customer", distributor_id: enterprise2.id.to_s
          expect(assigns(:users)).to_not include customer
        end

        it "performs no limitation when I specify a blank value for the shop" do
          spree_get :users, q: "customer", distributor_id: ''
          expect(assigns(:users)).to include customer
        end
      end
    end

    describe 'searching for known users' do

      describe "when search query is not an exact match" do
        before do
          spree_get :known_users, q: "test"
        end

        it "returns a list of users that I share management of enteprises with" do
          expect(assigns(:users)).to include owner, manager
          expect(assigns(:users)).to_not include random
        end
      end

      describe "when search query exactly matches the email of a user in the system" do
        before do
          spree_get :known_users, q: "test3@email.com"
        end

        it "returns that user, regardless of the relationship between the two users" do
          expect(assigns(:users)).to eq [random]
        end
      end
    end
  end
end
