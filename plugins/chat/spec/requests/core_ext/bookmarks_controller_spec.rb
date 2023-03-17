# frozen_string_literal: true

RSpec.describe BookmarksController do
  let(:current_user) { Fabricate(:user) }
  let(:bookmark_message) { Fabricate(:chat_message) }
  let(:bookmark_user) { current_user }

  before { sign_in(current_user) }

  context "when bookmarking a chat message" do
    describe "#create" do
      it "creates the bookmark" do
        post "/bookmarks.json",
             params: {
               bookmarkable_id: bookmark_message.id,
               bookmarkable_type: "Chat::Message",
               reminder_at: (Time.zone.now + 1.day).iso8601,
             }

        expect(response.status).to eq(200)
        expect(Bookmark.find_by(bookmarkable: bookmark_message).user_id).to eq(current_user.id)
      end
    end

    describe "#destroy" do
      let!(:bookmark) { Fabricate(:bookmark, bookmarkable: bookmark_message, user: bookmark_user) }

      it "destroys the bookmark" do
        delete "/bookmarks/#{bookmark.id}.json"

        expect(response.status).to eq(200)
        expect(Bookmark.find_by(id: bookmark.id)).to eq(nil)
      end
    end
  end
end
