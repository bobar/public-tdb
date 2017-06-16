class AccountController < ApplicationController
  def search
    accounts = Account.search(params[:term]).map do |a|
      {
        value: a.id,
        label: a.autocomplete_text,
        promo: a.promo,
        full_name: a.full_name,
        trigramme: a.trigramme,
        picture: a.fkz_picture,
        status: a.readable_status,
      }
    end
    render json: accounts
  end
end
