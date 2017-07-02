// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or any plugin's vendor/assets/javascripts directory can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file.
//
// Read Sprockets README (https://github.com/rails/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require jquery
//= require jquery_ujs
//= require jquery-ui/widgets/autocomplete
//= require datetimepicker
//= require moment
//= require eonasdan-bootstrap-datetimepicker
//= require_tree .
//= require bootstrap-sprockets
//= require bootstrap-datepicker
//= require timeago
//= require mousetrap.min

var letters = ['a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x','y','z',
               'A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z']; // eslint-disable-line indent
var numbers = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];

function inputFocused() {
  return document.activeElement.tagName === 'INPUT';
}

function bind(shortcut, handler, return_true) {
  Mousetrap.bind(shortcut, function() {
    if (inputFocused()) return ;
    handler();
    return return_true ? true : false;
  }, 'keydown');
}

$(document).ready(function() {
  $('time.timeago').timeago();
  $('.datetimepicker.begin').datetimepicker({
    format: 'YYYY-MM-DD HH:mm',
    sideBySide: true,
    stepping: 15,
  });
  $('.datetimepicker.end').datetimepicker({
    format: 'YYYY-MM-DD HH:mm',
    sideBySide: true,
    stepping: 15,
    useCurrent: false,
  });
  $('.datetimepicker.begin').on('dp.change', function (e) {
    $('.datetimepicker.end').data('DateTimePicker').minDate(e.date);
  });
  $('.datetimepicker.end').on('dp.change', function (e) {
    $('.datetimepicker.begin').data('DateTimePicker').maxDate(e.date);
  });

  var slogans = $('span[id^="slogan-"]').hide();
  var i = 0;

  (function cycle() {
    slogans.eq(i).fadeIn(400).delay(2000).fadeOut(400, cycle);
    i = ++i % slogans.length;
  })();

  bind(letters, function() {
    $('#account-search').focus();
  }, true);

  bind(numbers.concat(['.']), function() {
    $('#amount').focus();
  }, true);

  $('#account-search').autocomplete({
    autoFocus: true,
    source: '/account/search',
    minLength: 3,
    focus: function() {
      return false;
    },
    select: function(event, ui) {
      $('#trigramme').text(ui.item.trigramme);
      $('#full_name').text(ui.item.full_name);
      $('#promo').text(ui.item.promo + ' - ' + ui.item.status);
      $('#promo').toggleClass('text-danger', ui.item.status !== 'X platal');
      $('#_account_id').val(ui.item.value);
      $('.account-image').attr('src', ui.item.picture);
      $('#amount').focus();
      $('#account-search').val('');
      return false;
    }
  });
});

$(document).ajaxError(function(e, jqXHR) {
  if (jqXHR.statusText === 'canceled' || jqXHR.status === 200) {
    return;
  }
  try {
    if(typeof jqXHR.responseJSON === 'undefined') {
      $('#error-modal #error-modal-text').html(JSON.parse(jqXHR.responseText)['message']);
    } else {
      $('#error-modal #error-modal-text').html(jqXHR.responseJSON['message']);
    }
  } catch(e) {
    $('#error-modal #error-modal-text').text('Something went wrong, call the SIE.');
  }
  $('#error-modal').modal('show');
});
