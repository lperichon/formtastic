# coding: utf-8
require File.join(File.dirname(__FILE__), *%w[.. lib formtastic semantic_form_builder])
require File.join(File.dirname(__FILE__), *%w[.. lib formtastic semantic_form_helper])
ActionView::Base.send :include, Formtastic::SemanticFormHelper
