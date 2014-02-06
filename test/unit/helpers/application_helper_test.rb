# encoding: utf-8
#
# Redmine - project management software
# Copyright (C) 2006-2014  Jean-Philippe Lang
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

require File.expand_path('../../../test_helper', __FILE__)

class ApplicationHelperTest < ActionView::TestCase
  include Redmine::I18n
  include ERB::Util
  include Rails.application.routes.url_helpers

  fixtures :projects, :roles, :enabled_modules, :users,
           :repositories, :changesets,
           :trackers, :issue_statuses, :issues, :versions, :documents,
           :wikis, :wiki_pages, :wiki_contents,
           :boards, :messages, :news,
           :attachments, :enumerations

  def setup
    super
    set_tmp_attachments_directory
    @russian_test = "\xd1\x82\xd0\xb5\xd1\x81\xd1\x82"
    if @russian_test.respond_to?(:force_encoding)
      @russian_test.force_encoding('UTF-8')
    end
  end

  test "#link_to_if_authorized for authorized user should allow using the :controller and :action for the target link" do
    User.current = User.find_by_login('admin')

    @project = Issue.first.project # Used by helper
    response = link_to_if_authorized('By controller/actionr',
                                    {:controller => 'issues', :action => 'edit', :id => Issue.first.id})
    assert_match /href/, response
  end

  test "#link_to_if_authorized for unauthorized user should display nothing if user isn't authorized" do
    User.current = User.find_by_login('dlopper')
    @project = Project.find('private-child')
    issue = @project.issues.first
    assert !issue.visible?

    response = link_to_if_authorized('Never displayed',
                                    {:controller => 'issues', :action => 'show', :id => issue})
    assert_nil response
  end

  def test_auto_links
    to_test = {
      'http://foo.bar' => '<a class="external" href="http://foo.bar">http://foo.bar</a>',
      'http://foo.bar/~user' => '<a class="external" href="http://foo.bar/~user">http://foo.bar/~user</a>',
      'http://foo.bar.' => '<a class="external" href="http://foo.bar">http://foo.bar</a>.',
      'https://foo.bar.' => '<a class="external" href="https://foo.bar">https://foo.bar</a>.',
      'This is a link: http://foo.bar.' => 'This is a link: <a class="external" href="http://foo.bar">http://foo.bar</a>.',
      'A link (eg. http://foo.bar).' => 'A link (eg. <a class="external" href="http://foo.bar">http://foo.bar</a>).',
      'http://foo.bar/foo.bar#foo.bar.' => '<a class="external" href="http://foo.bar/foo.bar#foo.bar">http://foo.bar/foo.bar#foo.bar</a>.',
      'http://www.foo.bar/Test_(foobar)' => '<a class="external" href="http://www.foo.bar/Test_(foobar)">http://www.foo.bar/Test_(foobar)</a>',
      '(see inline link : http://www.foo.bar/Test_(foobar))' => '(see inline link : <a class="external" href="http://www.foo.bar/Test_(foobar)">http://www.foo.bar/Test_(foobar)</a>)',
      '(see inline link : http://www.foo.bar/Test)' => '(see inline link : <a class="external" href="http://www.foo.bar/Test">http://www.foo.bar/Test</a>)',
      '(see inline link : http://www.foo.bar/Test).' => '(see inline link : <a class="external" href="http://www.foo.bar/Test">http://www.foo.bar/Test</a>).',
      '(see "inline link":http://www.foo.bar/Test_(foobar))' => '(see <a href="http://www.foo.bar/Test_(foobar)" class="external">inline link</a>)',
      '(see "inline link":http://www.foo.bar/Test)' => '(see <a href="http://www.foo.bar/Test" class="external">inline link</a>)',
      '(see "inline link":http://www.foo.bar/Test).' => '(see <a href="http://www.foo.bar/Test" class="external">inline link</a>).',
      'www.foo.bar' => '<a class="external" href="http://www.foo.bar">www.foo.bar</a>',
      'http://foo.bar/page?p=1&t=z&s=' => '<a class="external" href="http://foo.bar/page?p=1&#38;t=z&#38;s=">http://foo.bar/page?p=1&#38;t=z&#38;s=</a>',
      'http://foo.bar/page#125' => '<a class="external" href="http://foo.bar/page#125">http://foo.bar/page#125</a>',
      'http://foo@www.bar.com' => '<a class="external" href="http://foo@www.bar.com">http://foo@www.bar.com</a>',
      'http://foo:bar@www.bar.com' => '<a class="external" href="http://foo:bar@www.bar.com">http://foo:bar@www.bar.com</a>',
      'ftp://foo.bar' => '<a class="external" href="ftp://foo.bar">ftp://foo.bar</a>',
      'ftps://foo.bar' => '<a class="external" href="ftps://foo.bar">ftps://foo.bar</a>',
      'sftp://foo.bar' => '<a class="external" href="sftp://foo.bar">sftp://foo.bar</a>',
      # two exclamation marks
      'http://example.net/path!602815048C7B5C20!302.html' => '<a class="external" href="http://example.net/path!602815048C7B5C20!302.html">http://example.net/path!602815048C7B5C20!302.html</a>',
      # escaping
      'http://foo"bar' => '<a class="external" href="http://foo&quot;bar">http://foo&quot;bar</a>',
      # wrap in angle brackets
      '<http://foo.bar>' => '&lt;<a class="external" href="http://foo.bar">http://foo.bar</a>&gt;',
      # invalid urls
      'http://' => 'http://',
      'www.' => 'www.',
      'test-www.bar.com' => 'test-www.bar.com',
    }
    to_test.each { |text, result| assert_equal "<p>#{result}</p>", textilizable(text) }
  end

  if 'ruby'.respond_to?(:encoding)
    def test_auto_links_with_non_ascii_characters
      to_test = {
        "http://foo.bar/#{@russian_test}" =>
          %|<a class="external" href="http://foo.bar/#{@russian_test}">http://foo.bar/#{@russian_test}</a>|
      }
      to_test.each { |text, result| assert_equal "<p>#{result}</p>", textilizable(text) }
    end
  else
    puts 'Skipping test_auto_links_with_non_ascii_characters, unsupported ruby version'
  end

  def test_auto_mailto
    to_test = {
      'test@foo.bar' => '<a class="email" href="mailto:test@foo.bar">test@foo.bar</a>',
      'test@www.foo.bar' => '<a class="email" href="mailto:test@www.foo.bar">test@www.foo.bar</a>',
    }
    to_test.each { |text, result| assert_equal "<p>#{result}</p>", textilizable(text) }
  end

  def test_inline_images
    to_test = {
      '!http://foo.bar/image.jpg!' => '<img src="http://foo.bar/image.jpg" alt="" />',
      'floating !>http://foo.bar/image.jpg!' => 'floating <div style="float:right"><img src="http://foo.bar/image.jpg" alt="" /></div>',
      'with class !(some-class)http://foo.bar/image.jpg!' => 'with class <img src="http://foo.bar/image.jpg" class="some-class" alt="" />',
      'with style !{width:100px;height:100px}http://foo.bar/image.jpg!' => 'with style <img src="http://foo.bar/image.jpg" style="width:100px;height:100px;" alt="" />',
      'with title !http://foo.bar/image.jpg(This is a title)!' => 'with title <img src="http://foo.bar/image.jpg" title="This is a title" alt="This is a title" />',
      'with title !http://foo.bar/image.jpg(This is a double-quoted "title")!' => 'with title <img src="http://foo.bar/image.jpg" title="This is a double-quoted &quot;title&quot;" alt="This is a double-quoted &quot;title&quot;" />',
    }
    to_test.each { |text, result| assert_equal "<p>#{result}</p>", textilizable(text) }
  end

  def test_inline_images_inside_tags
    raw = <<-RAW
h1. !foo.png! Heading

Centered image:

p=. !bar.gif!
RAW

    assert textilizable(raw).include?('<img src="foo.png" alt="" />')
    assert textilizable(raw).include?('<img src="bar.gif" alt="" />')
  end

  def test_attached_images
    to_test = {
      'Inline image: !logo.gif!' => 'Inline image: <img src="/attachments/download/3/logo.gif" title="This is a logo" alt="This is a logo" />',
      'Inline image: !logo.GIF!' => 'Inline image: <img src="/attachments/download/3/logo.gif" title="This is a logo" alt="This is a logo" />',
      'No match: !ogo.gif!' => 'No match: <img src="ogo.gif" alt="" />',
      'No match: !ogo.GIF!' => 'No match: <img src="ogo.GIF" alt="" />',
      # link image
      '!logo.gif!:http://foo.bar/' => '<a href="http://foo.bar/"><img src="/attachments/download/3/logo.gif" title="This is a logo" alt="This is a logo" /></a>',
    }
    attachments = Attachment.all
    to_test.each { |text, result| assert_equal "<p>#{result}</p>", textilizable(text, :attachments => attachments) }
  end

  def test_attached_images_filename_extension
    set_tmp_attachments_directory
    a1 = Attachment.new(
            :container => Issue.find(1),
            :file => mock_file_with_options({:original_filename => "testtest.JPG"}),
            :author => User.find(1))
    assert a1.save
    assert_equal "testtest.JPG", a1.filename
    assert_equal "image/jpeg", a1.content_type
    assert a1.image?

    a2 = Attachment.new(
            :container => Issue.find(1),
            :file => mock_file_with_options({:original_filename => "testtest.jpeg"}),
            :author => User.find(1))
    assert a2.save
    assert_equal "testtest.jpeg", a2.filename
    assert_equal "image/jpeg", a2.content_type
    assert a2.image?

    a3 = Attachment.new(
            :container => Issue.find(1),
            :file => mock_file_with_options({:original_filename => "testtest.JPE"}),
            :author => User.find(1))
    assert a3.save
    assert_equal "testtest.JPE", a3.filename
    assert_equal "image/jpeg", a3.content_type
    assert a3.image?

    a4 = Attachment.new(
            :container => Issue.find(1),
            :file => mock_file_with_options({:original_filename => "Testtest.BMP"}),
            :author => User.find(1))
    assert a4.save
    assert_equal "Testtest.BMP", a4.filename
    assert_equal "image/x-ms-bmp", a4.content_type
    assert a4.image?

    to_test = {
      'Inline image: !testtest.jpg!' =>
        'Inline image: <img src="/attachments/download/' + a1.id.to_s + '/testtest.JPG" alt="" />',
      'Inline image: !testtest.jpeg!' =>
        'Inline image: <img src="/attachments/download/' + a2.id.to_s + '/testtest.jpeg" alt="" />',
      'Inline image: !testtest.jpe!' =>
        'Inline image: <img src="/attachments/download/' + a3.id.to_s + '/testtest.JPE" alt="" />',
      'Inline image: !testtest.bmp!' =>
        'Inline image: <img src="/attachments/download/' + a4.id.to_s + '/Testtest.BMP" alt="" />',
    }

    attachments = [a1, a2, a3, a4]
    to_test.each { |text, result| assert_equal "<p>#{result}</p>", textilizable(text, :attachments => attachments) }
  end

  def test_attached_images_should_read_later
    set_fixtures_attachments_directory
    a1 = Attachment.find(16)
    assert_equal "testfile.png", a1.filename
    assert a1.readable?
    assert (! a1.visible?(User.anonymous))
    assert a1.visible?(User.find(2))
    a2 = Attachment.find(17)
    assert_equal "testfile.PNG", a2.filename
    assert a2.readable?
    assert (! a2.visible?(User.anonymous))
    assert a2.visible?(User.find(2))
    assert a1.created_on < a2.created_on

    to_test = {
      'Inline image: !testfile.png!' =>
        'Inline image: <img src="/attachments/download/' + a2.id.to_s + '/testfile.PNG" alt="" />',
      'Inline image: !Testfile.PNG!' =>
        'Inline image: <img src="/attachments/download/' + a2.id.to_s + '/testfile.PNG" alt="" />',
    }
    attachments = [a1, a2]
    to_test.each { |text, result| assert_equal "<p>#{result}</p>", textilizable(text, :attachments => attachments) }
    set_tmp_attachments_directory
  end

  def test_textile_external_links
    to_test = {
      'This is a "link":http://foo.bar' => 'This is a <a href="http://foo.bar" class="external">link</a>',
      'This is an intern "link":/foo/bar' => 'This is an intern <a href="/foo/bar">link</a>',
      '"link (Link title)":http://foo.bar' => '<a href="http://foo.bar" title="Link title" class="external">link</a>',
      '"link (Link title with "double-quotes")":http://foo.bar' => '<a href="http://foo.bar" title="Link title with &quot;double-quotes&quot;" class="external">link</a>',
      "This is not a \"Link\":\n\nAnother paragraph" => "This is not a \"Link\":</p>\n\n\n\t<p>Another paragraph",
      # no multiline link text
      "This is a double quote \"on the first line\nand another on a second line\":test" => "This is a double quote \"on the first line<br />and another on a second line\":test",
      # mailto link
      "\"system administrator\":mailto:sysadmin@example.com?subject=redmine%20permissions" => "<a href=\"mailto:sysadmin@example.com?subject=redmine%20permissions\">system administrator</a>",
      # two exclamation marks
      '"a link":http://example.net/path!602815048C7B5C20!302.html' => '<a href="http://example.net/path!602815048C7B5C20!302.html" class="external">a link</a>',
      # escaping
      '"test":http://foo"bar' => '<a href="http://foo&quot;bar" class="external">test</a>',
    }
    to_test.each { |text, result| assert_equal "<p>#{result}</p>", textilizable(text) }
  end

  if 'ruby'.respond_to?(:encoding)
    def test_textile_external_links_with_non_ascii_characters
      to_test = {
        %|This is a "link":http://foo.bar/#{@russian_test}| =>
          %|This is a <a href="http://foo.bar/#{@russian_test}" class="external">link</a>|
      }
      to_test.each { |text, result| assert_equal "<p>#{result}</p>", textilizable(text) }
    end
  else
    puts 'Skipping test_textile_external_links_with_non_ascii_characters, unsupported ruby version'
  end

  def test_redmine_links
    issue_link = link_to('#3', {:controller => 'issues', :action => 'show', :id => 3},
                               :class => Issue.find(3).css_classes, :title => 'Error 281 when updating a recipe (New)')
    note_link = link_to('#3-14', {:controller => 'issues', :action => 'show', :id => 3, :anchor => 'note-14'},
                               :class => Issue.find(3).css_classes, :title => 'Error 281 when updating a recipe (New)')
    note_link2 = link_to('#3#note-14', {:controller => 'issues', :action => 'show', :id => 3, :anchor => 'note-14'},
                               :class => Issue.find(3).css_classes, :title => 'Error 281 when updating a recipe (New)')

    revision_link = link_to('r1', {:controller => 'repositories', :action => 'revision', :id => 'ecookbook', :rev => 1},
                                   :class => 'changeset', :title => 'My very first commit do not escaping #<>&')
    revision_link2 = link_to('r2', {:controller => 'repositories', :action => 'revision', :id => 'ecookbook', :rev => 2},
                                    :class => 'changeset', :title => 'This commit fixes #1, #2 and references #1 & #3')

    changeset_link2 = link_to('691322a8eb01e11fd7',
                              {:controller => 'repositories', :action => 'revision', :id => 'ecookbook', :rev => 1},
                               :class => 'changeset', :title => 'My very first commit do not escaping #<>&')

    document_link = link_to('Test document', {:controller => 'documents', :action => 'show', :id => 1},
                                             :class => 'document')

    version_link = link_to('1.0', {:controller => 'versions', :action => 'show', :id => 2},
                                  :class => 'version')

    board_url = {:controller => 'boards', :action => 'show', :id => 2, :project_id => 'ecookbook'}

    message_url = {:controller => 'messages', :action => 'show', :board_id => 1, :id => 4}
    
    news_url = {:controller => 'news', :action => 'show', :id => 1}

    project_url = {:controller => 'projects', :action => 'show', :id => 'subproject1'}

    source_url = '/projects/ecookbook/repository/entry/some/file'
    source_url_with_rev = '/projects/ecookbook/repository/revisions/52/entry/some/file'
    source_url_with_ext = '/projects/ecookbook/repository/entry/some/file.ext'
    source_url_with_rev_and_ext = '/projects/ecookbook/repository/revisions/52/entry/some/file.ext'
    source_url_with_branch = '/projects/ecookbook/repository/revisions/branch/entry/some/file'

    export_url = '/projects/ecookbook/repository/raw/some/file'
    export_url_with_rev = '/projects/ecookbook/repository/revisions/52/raw/some/file'
    export_url_with_ext = '/projects/ecookbook/repository/raw/some/file.ext'
    export_url_with_rev_and_ext = '/projects/ecookbook/repository/revisions/52/raw/some/file.ext'
    export_url_with_branch = '/projects/ecookbook/repository/revisions/branch/raw/some/file'

    to_test = {
      # tickets
      '#3, [#3], (#3) and #3.'      => "#{issue_link}, [#{issue_link}], (#{issue_link}) and #{issue_link}.",
      # ticket notes
      '#3-14'                       => note_link,
      '#3#note-14'                  => note_link2,
      # should not ignore leading zero
      '#03'                         => '#03',
      # changesets
      'r1'                          => revision_link,
      'r1.'                         => "#{revision_link}.",
      'r1, r2'                      => "#{revision_link}, #{revision_link2}",
      'r1,r2'                       => "#{revision_link},#{revision_link2}",
      'commit:691322a8eb01e11fd7'   => changeset_link2,
      # documents
      'document#1'                  => document_link,
      'document:"Test document"'    => document_link,
      # versions
      'version#2'                   => version_link,
      'version:1.0'                 => version_link,
      'version:"1.0"'               => version_link,
      # source
      'source:some/file'            => link_to('source:some/file', source_url, :class => 'source'),
      'source:/some/file'           => link_to('source:/some/file', source_url, :class => 'source'),
      'source:/some/file.'          => link_to('source:/some/file', source_url, :class => 'source') + ".",
      'source:/some/file.ext.'      => link_to('source:/some/file.ext', source_url_with_ext, :class => 'source') + ".",
      'source:/some/file. '         => link_to('source:/some/file', source_url, :class => 'source') + ".",
      'source:/some/file.ext. '     => link_to('source:/some/file.ext', source_url_with_ext, :class => 'source') + ".",
      'source:/some/file, '         => link_to('source:/some/file', source_url, :class => 'source') + ",",
      'source:/some/file@52'        => link_to('source:/some/file@52', source_url_with_rev, :class => 'source'),
      'source:/some/file@branch'    => link_to('source:/some/file@branch', source_url_with_branch, :class => 'source'),
      'source:/some/file.ext@52'    => link_to('source:/some/file.ext@52', source_url_with_rev_and_ext, :class => 'source'),
      'source:/some/file#L110'      => link_to('source:/some/file#L110', source_url + "#L110", :class => 'source'),
      'source:/some/file.ext#L110'  => link_to('source:/some/file.ext#L110', source_url_with_ext + "#L110", :class => 'source'),
      'source:/some/file@52#L110'   => link_to('source:/some/file@52#L110', source_url_with_rev + "#L110", :class => 'source'),
      # export
      'export:/some/file'           => link_to('export:/some/file', export_url, :class => 'source download'),
      'export:/some/file.ext'       => link_to('export:/some/file.ext', export_url_with_ext, :class => 'source download'),
      'export:/some/file@52'        => link_to('export:/some/file@52', export_url_with_rev, :class => 'source download'),
      'export:/some/file.ext@52'    => link_to('export:/some/file.ext@52', export_url_with_rev_and_ext, :class => 'source download'),
      'export:/some/file@branch'    => link_to('export:/some/file@branch', export_url_with_branch, :class => 'source download'),
      # forum
      'forum#2'                     => link_to('Discussion', board_url, :class => 'board'),
      'forum:Discussion'            => link_to('Discussion', board_url, :class => 'board'),
      # message
      'message#4'                   => link_to('Post 2', message_url, :class => 'message'),
      'message#5'                   => link_to('RE: post 2', message_url.merge(:anchor => 'message-5', :r => 5), :class => 'message'),
      # news
      'news#1'                      => link_to('eCookbook first release !', news_url, :class => 'news'),
      'news:"eCookbook first release !"'        => link_to('eCookbook first release !', news_url, :class => 'news'),
      # project
      'project#3'                   => link_to('eCookbook Subproject 1', project_url, :class => 'project'),
      'project:subproject1'         => link_to('eCookbook Subproject 1', project_url, :class => 'project'),
      'project:"eCookbook subProject 1"'        => link_to('eCookbook Subproject 1', project_url, :class => 'project'),
      # not found
      '#0123456789'                 => '#0123456789',
      # invalid expressions
      'source:'                     => 'source:',
      # url hash
      "http://foo.bar/FAQ#3"       => '<a class="external" href="http://foo.bar/FAQ#3">http://foo.bar/FAQ#3</a>',
    }
    @project = Project.find(1)
    to_test.each { |text, result| assert_equal "<p>#{result}</p>", textilizable(text), "#{text} failed" }
  end

  def test_redmine_links_with_a_different_project_before_current_project
    vp1 = Version.generate!(:project_id => 1, :name => '1.4.4')
    vp3 = Version.generate!(:project_id => 3, :name => '1.4.4')
    @project = Project.find(3)
    result1 = link_to("1.4.4", "/versions/#{vp1.id}", :class => "version")
    result2 = link_to("1.4.4", "/versions/#{vp3.id}", :class => "version")
    assert_equal "<p>#{result1} #{result2}</p>",
                 textilizable("ecookbook:version:1.4.4 version:1.4.4")
  end

  def test_escaped_redmine_links_should_not_be_parsed
    to_test = [
      '#3.',
      '#3-14.',
      '#3#-note14.',
      'r1',
      'document#1',
      'document:"Test document"',
      'version#2',
      'version:1.0',
      'version:"1.0"',
      'source:/some/file'
    ]
    @project = Project.find(1)
    to_test.each { |text| assert_equal "<p>#{text}</p>", textilizable("!" + text), "#{text} failed" }
  end

  def test_cross_project_redmine_links
    source_link = link_to('ecookbook:source:/some/file',
                          {:controller => 'repositories', :action => 'entry',
                           :id => 'ecookbook', :path => ['some', 'file']},
                          :class => 'source')
    changeset_link = link_to('ecookbook:r2',
                             {:controller => 'repositories', :action => 'revision',
                              :id => 'ecookbook', :rev => 2},
                             :class => 'changeset',
                             :title => 'This commit fixes #1, #2 and references #1 & #3')
    to_test = {
      # documents
      'document:"Test document"'              => 'document:"Test document"',
      'ecookbook:document:"Test document"'    =>
          link_to("Test document", "/documents/1", :class => "document"),
      'invalid:document:"Test document"'      => 'invalid:document:"Test document"',
      # versions
      'version:"1.0"'                         => 'version:"1.0"',
      'ecookbook:version:"1.0"'               =>
          link_to("1.0", "/versions/2", :class => "version"),
      'invalid:version:"1.0"'                 => 'invalid:version:"1.0"',
      # changeset
      'r2'                                    => 'r2',
      'ecookbook:r2'                          => changeset_link,
      'invalid:r2'                            => 'invalid:r2',
      # source
      'source:/some/file'                     => 'source:/some/file',
      'ecookbook:source:/some/file'           => source_link,
      'invalid:source:/some/file'             => 'invalid:source:/some/file',
    }
    @project = Project.find(3)
    to_test.each do |text, result|
      assert_equal "<p>#{result}</p>", textilizable(text), "#{text} failed"
    end
  end

  def test_multiple_repositories_redmine_links
    svn = Repository::Subversion.create!(:project_id => 1, :identifier => 'svn_repo-1', :url => 'file:///foo/hg')
    Changeset.create!(:repository => svn, :committed_on => Time.now, :revision => '123')
    hg = Repository::Mercurial.create!(:project_id => 1, :identifier => 'hg1', :url => '/foo/hg')
    Changeset.create!(:repository => hg, :committed_on => Time.now, :revision => '123', :scmid => 'abcd')

    changeset_link = link_to('r2', {:controller => 'repositories', :action => 'revision', :id => 'ecookbook', :rev => 2},
                                    :class => 'changeset', :title => 'This commit fixes #1, #2 and references #1 & #3')
    svn_changeset_link = link_to('svn_repo-1|r123', {:controller => 'repositories', :action => 'revision', :id => 'ecookbook', :repository_id => 'svn_repo-1', :rev => 123},
                                    :class => 'changeset', :title => '')
    hg_changeset_link = link_to('hg1|abcd', {:controller => 'repositories', :action => 'revision', :id => 'ecookbook', :repository_id => 'hg1', :rev => 'abcd'},
                                    :class => 'changeset', :title => '')

    source_link = link_to('source:some/file', {:controller => 'repositories', :action => 'entry', :id => 'ecookbook', :path => ['some', 'file']}, :class => 'source')
    hg_source_link = link_to('source:hg1|some/file', {:controller => 'repositories', :action => 'entry', :id => 'ecookbook', :repository_id => 'hg1', :path => ['some', 'file']}, :class => 'source')

    to_test = {
      'r2'                          => changeset_link,
      'svn_repo-1|r123'             => svn_changeset_link,
      'invalid|r123'                => 'invalid|r123',
      'commit:hg1|abcd'             => hg_changeset_link,
      'commit:invalid|abcd'         => 'commit:invalid|abcd',
      # source
      'source:some/file'            => source_link,
      'source:hg1|some/file'        => hg_source_link,
      'source:invalid|some/file'    => 'source:invalid|some/file',
    }

    @project = Project.find(1)
    to_test.each { |text, result| assert_equal "<p>#{result}</p>", textilizable(text), "#{text} failed" }
  end

  def test_cross_project_multiple_repositories_redmine_links
    svn = Repository::Subversion.create!(:project_id => 1, :identifier => 'svn1', :url => 'file:///foo/hg')
    Changeset.create!(:repository => svn, :committed_on => Time.now, :revision => '123')
    hg = Repository::Mercurial.create!(:project_id => 1, :identifier => 'hg1', :url => '/foo/hg')
    Changeset.create!(:repository => hg, :committed_on => Time.now, :revision => '123', :scmid => 'abcd')

    changeset_link = link_to('ecookbook:r2', {:controller => 'repositories', :action => 'revision', :id => 'ecookbook', :rev => 2},
                                    :class => 'changeset', :title => 'This commit fixes #1, #2 and references #1 & #3')
    svn_changeset_link = link_to('ecookbook:svn1|r123', {:controller => 'repositories', :action => 'revision', :id => 'ecookbook', :repository_id => 'svn1', :rev => 123},
                                    :class => 'changeset', :title => '')
    hg_changeset_link = link_to('ecookbook:hg1|abcd', {:controller => 'repositories', :action => 'revision', :id => 'ecookbook', :repository_id => 'hg1', :rev => 'abcd'},
                                    :class => 'changeset', :title => '')

    source_link = link_to('ecookbook:source:some/file', {:controller => 'repositories', :action => 'entry', :id => 'ecookbook', :path => ['some', 'file']}, :class => 'source')
    hg_source_link = link_to('ecookbook:source:hg1|some/file', {:controller => 'repositories', :action => 'entry', :id => 'ecookbook', :repository_id => 'hg1', :path => ['some', 'file']}, :class => 'source')

    to_test = {
      'ecookbook:r2'                           => changeset_link,
      'ecookbook:svn1|r123'                    => svn_changeset_link,
      'ecookbook:invalid|r123'                 => 'ecookbook:invalid|r123',
      'ecookbook:commit:hg1|abcd'              => hg_changeset_link,
      'ecookbook:commit:invalid|abcd'          => 'ecookbook:commit:invalid|abcd',
      'invalid:commit:invalid|abcd'            => 'invalid:commit:invalid|abcd',
      # source
      'ecookbook:source:some/file'             => source_link,
      'ecookbook:source:hg1|some/file'         => hg_source_link,
      'ecookbook:source:invalid|some/file'     => 'ecookbook:source:invalid|some/file',
      'invalid:source:invalid|some/file'       => 'invalid:source:invalid|some/file',
    }

    @project = Project.find(3)
    to_test.each { |text, result| assert_equal "<p>#{result}</p>", textilizable(text), "#{text} failed" }
  end

  def test_redmine_links_git_commit
    changeset_link = link_to('abcd',
                               {
                                 :controller => 'repositories',
                                 :action     => 'revision',
                                 :id         => 'subproject1',
                                 :rev        => 'abcd',
                                },
                              :class => 'changeset', :title => 'test commit')
    to_test = {
      'commit:abcd' => changeset_link,
     }
    @project = Project.find(3)
    r = Repository::Git.create!(:project => @project, :url => '/tmp/test/git')
    assert r
    c = Changeset.new(:repository => r,
                      :committed_on => Time.now,
                      :revision => 'abcd',
                      :scmid => 'abcd',
                      :comments => 'test commit')
    assert( c.save )
    to_test.each { |text, result| assert_equal "<p>#{result}</p>", textilizable(text) }
  end

  # TODO: Bazaar commit id contains mail address, so it contains '@' and '_'.
  def test_redmine_links_darcs_commit
    changeset_link = link_to('20080308225258-98289-abcd456efg.gz',
                               {
                                 :controller => 'repositories',
                                 :action     => 'revision',
                                 :id         => 'subproject1',
                                 :rev        => '123',
                                },
                              :class => 'changeset', :title => 'test commit')
    to_test = {
      'commit:20080308225258-98289-abcd456efg.gz' => changeset_link,
     }
    @project = Project.find(3)
    r = Repository::Darcs.create!(
            :project => @project, :url => '/tmp/test/darcs',
            :log_encoding => 'UTF-8')
    assert r
    c = Changeset.new(:repository => r,
                      :committed_on => Time.now,
                      :revision => '123',
                      :scmid => '20080308225258-98289-abcd456efg.gz',
                      :comments => 'test commit')
    assert( c.save )
    to_test.each { |text, result| assert_equal "<p>#{result}</p>", textilizable(text) }
  end

  def test_redmine_links_mercurial_commit
    changeset_link_rev = link_to('r123',
                                  {
                                     :controller => 'repositories',
                                     :action     => 'revision',
                                     :id         => 'subproject1',
                                     :rev        => '123' ,
                                  },
                              :class => 'changeset', :title => 'test commit')
    changeset_link_commit = link_to('abcd',
                                  {
                                        :controller => 'repositories',
                                        :action     => 'revision',
                                        :id         => 'subproject1',
                                        :rev        => 'abcd' ,
                                  },
                              :class => 'changeset', :title => 'test commit')
    to_test = {
      'r123' => changeset_link_rev,
      'commit:abcd' => changeset_link_commit,
     }
    @project = Project.find(3)
    r = Repository::Mercurial.create!(:project => @project, :url => '/tmp/test')
    assert r
    c = Changeset.new(:repository => r,
                      :committed_on => Time.now,
                      :revision => '123',
                      :scmid => 'abcd',
                      :comments => 'test commit')
    assert( c.save )
    to_test.each { |text, result| assert_equal "<p>#{result}</p>", textilizable(text) }
  end

  def test_attachment_links
    text = 'attachment:error281.txt'
    result = link_to("error281.txt", "/attachments/download/1/error281.txt",
                     :class => "attachment")
    assert_equal "<p>#{result}</p>",
                 textilizable(text,
                              :attachments => Issue.find(3).attachments),
                 "#{text} failed"
  end

  def test_attachment_link_should_link_to_latest_attachment
    set_tmp_attachments_directory
    a1 = Attachment.generate!(:filename => "test.txt", :created_on => 1.hour.ago)
    a2 = Attachment.generate!(:filename => "test.txt")
    result = link_to("test.txt", "/attachments/download/#{a2.id}/test.txt",
                     :class => "attachment")
    assert_equal "<p>#{result}</p>",
                 textilizable('attachment:test.txt', :attachments => [a1, a2])
  end

  def test_wiki_links
    russian_eacape = CGI.escape(@russian_test)
    to_test = {
      '[[CookBook documentation]]' => '<a href="/projects/ecookbook/wiki/CookBook_documentation" class="wiki-page">CookBook documentation</a>',
      '[[Another page|Page]]' => '<a href="/projects/ecookbook/wiki/Another_page" class="wiki-page">Page</a>',
      # title content should be formatted
      '[[Another page|With _styled_ *title*]]' => '<a href="/projects/ecookbook/wiki/Another_page" class="wiki-page">With <em>styled</em> <strong>title</strong></a>',
      '[[Another page|With title containing <strong>HTML entities &amp; markups</strong>]]' => '<a href="/projects/ecookbook/wiki/Another_page" class="wiki-page">With title containing &lt;strong&gt;HTML entities &amp; markups&lt;/strong&gt;</a>',
      # link with anchor
      '[[CookBook documentation#One-section]]' => '<a href="/projects/ecookbook/wiki/CookBook_documentation#One-section" class="wiki-page">CookBook documentation</a>',
      '[[Another page#anchor|Page]]' => '<a href="/projects/ecookbook/wiki/Another_page#anchor" class="wiki-page">Page</a>',
      # UTF8 anchor
      "[[Another_page##{@russian_test}|#{@russian_test}]]" =>
         %|<a href="/projects/ecookbook/wiki/Another_page##{russian_eacape}" class="wiki-page">#{@russian_test}</a>|,
      # page that doesn't exist
      '[[Unknown page]]' => '<a href="/projects/ecookbook/wiki/Unknown_page" class="wiki-page new">Unknown page</a>',
      '[[Unknown page|404]]' => '<a href="/projects/ecookbook/wiki/Unknown_page" class="wiki-page new">404</a>',
      # link to another project wiki
      '[[onlinestore:]]' => '<a href="/projects/onlinestore/wiki" class="wiki-page">onlinestore</a>',
      '[[onlinestore:|Wiki]]' => '<a href="/projects/onlinestore/wiki" class="wiki-page">Wiki</a>',
      '[[onlinestore:Start page]]' => '<a href="/projects/onlinestore/wiki/Start_page" class="wiki-page">Start page</a>',
      '[[onlinestore:Start page|Text]]' => '<a href="/projects/onlinestore/wiki/Start_page" class="wiki-page">Text</a>',
      '[[onlinestore:Unknown page]]' => '<a href="/projects/onlinestore/wiki/Unknown_page" class="wiki-page new">Unknown page</a>',
      # striked through link
      '-[[Another page|Page]]-' => '<del><a href="/projects/ecookbook/wiki/Another_page" class="wiki-page">Page</a></del>',
      '-[[Another page|Page]] link-' => '<del><a href="/projects/ecookbook/wiki/Another_page" class="wiki-page">Page</a> link</del>',
      # escaping
      '![[Another page|Page]]' => '[[Another page|Page]]',
      # project does not exist
      '[[unknowproject:Start]]' => '[[unknowproject:Start]]',
      '[[unknowproject:Start|Page title]]' => '[[unknowproject:Start|Page title]]',
    }

    @project = Project.find(1)
    to_test.each { |text, result| assert_equal "<p>#{result}</p>", textilizable(text) }
  end

  def test_wiki_links_within_local_file_generation_context
    to_test = {
      # link to a page
      '[[CookBook documentation]]' =>
         link_to("CookBook documentation", "CookBook_documentation.html",
                 :class => "wiki-page"),
      '[[CookBook documentation|documentation]]' =>
         link_to("documentation", "CookBook_documentation.html",
                 :class => "wiki-page"),
      '[[CookBook documentation#One-section]]' =>
         link_to("CookBook documentation", "CookBook_documentation.html#One-section",
                 :class => "wiki-page"),
      '[[CookBook documentation#One-section|documentation]]' =>
         link_to("documentation", "CookBook_documentation.html#One-section",
                 :class => "wiki-page"),
      # page that doesn't exist
      '[[Unknown page]]' =>
         link_to("Unknown page", "Unknown_page.html",
                 :class => "wiki-page new"),
      '[[Unknown page|404]]' =>
         link_to("404", "Unknown_page.html",
                 :class => "wiki-page new"),
      '[[Unknown page#anchor]]' =>
         link_to("Unknown page", "Unknown_page.html#anchor",
                 :class => "wiki-page new"),
      '[[Unknown page#anchor|404]]' =>
         link_to("404", "Unknown_page.html#anchor",
                 :class => "wiki-page new"),
    }
    @project = Project.find(1)
    to_test.each do |text, result|
      assert_equal "<p>#{result}</p>", textilizable(text, :wiki_links => :local)
    end
  end

  def test_wiki_links_within_wiki_page_context

    page = WikiPage.find_by_title('Another_page' )

    to_test = {
      # link to another page
      '[[CookBook documentation]]' => '<a href="/projects/ecookbook/wiki/CookBook_documentation" class="wiki-page">CookBook documentation</a>',
      '[[CookBook documentation|documentation]]' => '<a href="/projects/ecookbook/wiki/CookBook_documentation" class="wiki-page">documentation</a>',
      '[[CookBook documentation#One-section]]' => '<a href="/projects/ecookbook/wiki/CookBook_documentation#One-section" class="wiki-page">CookBook documentation</a>',
      '[[CookBook documentation#One-section|documentation]]' => '<a href="/projects/ecookbook/wiki/CookBook_documentation#One-section" class="wiki-page">documentation</a>',
      # link to the current page
      '[[Another page]]' => '<a href="/projects/ecookbook/wiki/Another_page" class="wiki-page">Another page</a>',
      '[[Another page|Page]]' => '<a href="/projects/ecookbook/wiki/Another_page" class="wiki-page">Page</a>',
      '[[Another page#anchor]]' => '<a href="#anchor" class="wiki-page">Another page</a>',
      '[[Another page#anchor|Page]]' => '<a href="#anchor" class="wiki-page">Page</a>',
      # page that doesn't exist
      '[[Unknown page]]' => '<a href="/projects/ecookbook/wiki/Unknown_page?parent=Another_page" class="wiki-page new">Unknown page</a>',
      '[[Unknown page|404]]' => '<a href="/projects/ecookbook/wiki/Unknown_page?parent=Another_page" class="wiki-page new">404</a>',
      '[[Unknown page#anchor]]' => '<a href="/projects/ecookbook/wiki/Unknown_page?parent=Another_page#anchor" class="wiki-page new">Unknown page</a>',
      '[[Unknown page#anchor|404]]' => '<a href="/projects/ecookbook/wiki/Unknown_page?parent=Another_page#anchor" class="wiki-page new">404</a>',
    }

    @project = Project.find(1)

    to_test.each { |text, result| assert_equal "<p>#{result}</p>", textilizable(WikiContent.new( :text => text, :page => page ), :text) }
  end

  def test_wiki_links_anchor_option_should_prepend_page_title_to_href
    to_test = {
      # link to a page
      '[[CookBook documentation]]' =>
          link_to("CookBook documentation",
                  "#CookBook_documentation",
                  :class => "wiki-page"),
      '[[CookBook documentation|documentation]]' =>
          link_to("documentation",
                  "#CookBook_documentation",
                  :class => "wiki-page"),
      '[[CookBook documentation#One-section]]' =>
          link_to("CookBook documentation",
                  "#CookBook_documentation_One-section",
                  :class => "wiki-page"),
      '[[CookBook documentation#One-section|documentation]]' =>
          link_to("documentation",
                  "#CookBook_documentation_One-section",
                  :class => "wiki-page"),
      # page that doesn't exist
      '[[Unknown page]]' =>
          link_to("Unknown page",
                  "#Unknown_page",
                  :class => "wiki-page new"),
      '[[Unknown page|404]]' =>
          link_to("404",
                  "#Unknown_page",
                  :class => "wiki-page new"),
      '[[Unknown page#anchor]]' =>
          link_to("Unknown page",
                  "#Unknown_page_anchor",
                  :class => "wiki-page new"),
      '[[Unknown page#anchor|404]]' =>
          link_to("404",
                  "#Unknown_page_anchor",
                  :class => "wiki-page new"),
    }
    @project = Project.find(1)
    to_test.each do |text, result|
      assert_equal "<p>#{result}</p>", textilizable(text, :wiki_links => :anchor)
    end
  end

  def test_html_tags
    to_test = {
      "<div>content</div>" => "<p>&lt;div&gt;content&lt;/div&gt;</p>",
      "<div class=\"bold\">content</div>" => "<p>&lt;div class=\"bold\"&gt;content&lt;/div&gt;</p>",
      "<script>some script;</script>" => "<p>&lt;script&gt;some script;&lt;/script&gt;</p>",
      # do not escape pre/code tags
      "<pre>\nline 1\nline2</pre>" => "<pre>\nline 1\nline2</pre>",
      "<pre><code>\nline 1\nline2</code></pre>" => "<pre><code>\nline 1\nline2</code></pre>",
      "<pre><div>content</div></pre>" => "<pre>&lt;div&gt;content&lt;/div&gt;</pre>",
      "HTML comment: <!-- no comments -->" => "<p>HTML comment: &lt;!-- no comments --&gt;</p>",
      "<!-- opening comment" => "<p>&lt;!-- opening comment</p>",
      # remove attributes except class
      "<pre class='foo'>some text</pre>" => "<pre class='foo'>some text</pre>",
      '<pre class="foo">some text</pre>' => '<pre class="foo">some text</pre>',
      "<pre class='foo bar'>some text</pre>" => "<pre class='foo bar'>some text</pre>",
      '<pre class="foo bar">some text</pre>' => '<pre class="foo bar">some text</pre>',
      "<pre onmouseover='alert(1)'>some text</pre>" => "<pre>some text</pre>",
      # xss
      '<pre><code class=""onmouseover="alert(1)">text</code></pre>' => '<pre><code>text</code></pre>',
      '<pre class=""onmouseover="alert(1)">text</pre>' => '<pre>text</pre>',
    }
    to_test.each { |text, result| assert_equal result, textilizable(text) }
  end

  def test_allowed_html_tags
    to_test = {
      "<pre>preformatted text</pre>" => "<pre>preformatted text</pre>",
      "<notextile>no *textile* formatting</notextile>" => "no *textile* formatting",
      "<notextile>this is <tag>a tag</tag></notextile>" => "this is &lt;tag&gt;a tag&lt;/tag&gt;"
    }
    to_test.each { |text, result| assert_equal result, textilizable(text) }
  end

  def test_pre_tags
    raw = <<-RAW
Before

<pre>
<prepared-statement-cache-size>32</prepared-statement-cache-size>
</pre>

After
RAW

    expected = <<-EXPECTED
<p>Before</p>
<pre>
&lt;prepared-statement-cache-size&gt;32&lt;/prepared-statement-cache-size&gt;
</pre>
<p>After</p>
EXPECTED

    assert_equal expected.gsub(%r{[\r\n\t]}, ''), textilizable(raw).gsub(%r{[\r\n\t]}, '')
  end

  def test_pre_content_should_not_parse_wiki_and_redmine_links
    raw = <<-RAW
[[CookBook documentation]]
  
#1

<pre>
[[CookBook documentation]]
  
#1
</pre>
RAW

    expected = <<-EXPECTED
<p><a href="/projects/ecookbook/wiki/CookBook_documentation" class="wiki-page">CookBook documentation</a></p>
<p><a href="/issues/1" class="#{Issue.find(1).css_classes}" title="#{ESCAPED_UCANT} print recipes (New)">#1</a></p>
<pre>
[[CookBook documentation]]

#1
</pre>
EXPECTED

    @project = Project.find(1)
    assert_equal expected.gsub(%r{[\r\n\t]}, ''), textilizable(raw).gsub(%r{[\r\n\t]}, '')
  end

  def test_non_closing_pre_blocks_should_be_closed
    raw = <<-RAW
<pre><code>
RAW

    expected = <<-EXPECTED
<pre><code>
</code></pre>
EXPECTED

    @project = Project.find(1)
    assert_equal expected.gsub(%r{[\r\n\t]}, ''), textilizable(raw).gsub(%r{[\r\n\t]}, '')
  end

  def test_syntax_highlight
    raw = <<-RAW
<pre><code class="ruby">
# Some ruby code here
</code></pre>
RAW

    expected = <<-EXPECTED
<pre><code class="ruby syntaxhl"><span class=\"CodeRay\"><span class="comment"># Some ruby code here</span></span>
</code></pre>
EXPECTED

    assert_equal expected.gsub(%r{[\r\n\t]}, ''), textilizable(raw).gsub(%r{[\r\n\t]}, '')
  end

  def test_to_path_param
    assert_equal 'test1/test2', to_path_param('test1/test2')
    assert_equal 'test1/test2', to_path_param('/test1/test2/')
    assert_equal 'test1/test2', to_path_param('//test1/test2/')
    assert_equal nil, to_path_param('/')
  end

  def test_wiki_links_in_tables
    text = "|[[Page|Link title]]|[[Other Page|Other title]]|\n|Cell 21|[[Last page]]|"
    link1 = link_to("Link title", "/projects/ecookbook/wiki/Page", :class => "wiki-page new")
    link2 = link_to("Other title", "/projects/ecookbook/wiki/Other_Page", :class => "wiki-page new")
    link3 = link_to("Last page", "/projects/ecookbook/wiki/Last_page", :class => "wiki-page new")
    result = "<tr><td>#{link1}</td>" +
               "<td>#{link2}</td>" +
               "</tr><tr><td>Cell 21</td><td>#{link3}</td></tr>"
    @project = Project.find(1)
    assert_equal "<table>#{result}</table>", textilizable(text).gsub(/[\t\n]/, '')
  end

  def test_text_formatting
    to_test = {'*_+bold, italic and underline+_*' => '<strong><em><ins>bold, italic and underline</ins></em></strong>',
               '(_text within parentheses_)' => '(<em>text within parentheses</em>)',
               'a *Humane Web* Text Generator' => 'a <strong>Humane Web</strong> Text Generator',
               'a H *umane* W *eb* T *ext* G *enerator*' => 'a H <strong>umane</strong> W <strong>eb</strong> T <strong>ext</strong> G <strong>enerator</strong>',
               'a *H* umane *W* eb *T* ext *G* enerator' => 'a <strong>H</strong> umane <strong>W</strong> eb <strong>T</strong> ext <strong>G</strong> enerator',
              }
    to_test.each { |text, result| assert_equal "<p>#{result}</p>", textilizable(text) }
  end

  def test_wiki_horizontal_rule
    assert_equal '<hr />', textilizable('---')
    assert_equal '<p>Dashes: ---</p>', textilizable('Dashes: ---')
  end

  def test_footnotes
    raw = <<-RAW
This is some text[1].

fn1. This is the foot note
RAW

    expected = <<-EXPECTED
<p>This is some text<sup><a href=\"#fn1\">1</a></sup>.</p>
<p id="fn1" class="footnote"><sup>1</sup> This is the foot note</p>
EXPECTED

    assert_equal expected.gsub(%r{[\r\n\t]}, ''), textilizable(raw).gsub(%r{[\r\n\t]}, '')
  end

  def test_headings
    raw = 'h1. Some heading'
    expected = %|<a name="Some-heading"></a>\n<h1 >Some heading<a href="#Some-heading" class="wiki-anchor">&para;</a></h1>|

    assert_equal expected, textilizable(raw)
  end

  def test_headings_with_special_chars
    # This test makes sure that the generated anchor names match the expected
    # ones even if the heading text contains unconventional characters
    raw = 'h1. Some heading related to version 0.5'
    anchor = sanitize_anchor_name("Some-heading-related-to-version-0.5")
    expected = %|<a name="#{anchor}"></a>\n<h1 >Some heading related to version 0.5<a href="##{anchor}" class="wiki-anchor">&para;</a></h1>|

    assert_equal expected, textilizable(raw)
  end

  def test_headings_in_wiki_single_page_export_should_be_prepended_with_page_title
    page = WikiPage.new( :title => 'Page Title', :wiki_id => 1 )
    content = WikiContent.new( :text => 'h1. Some heading', :page => page )

    expected = %|<a name="Page_Title_Some-heading"></a>\n<h1 >Some heading<a href="#Page_Title_Some-heading" class="wiki-anchor">&para;</a></h1>|

    assert_equal expected, textilizable(content, :text, :wiki_links => :anchor )
  end

  def test_table_of_content
    raw = <<-RAW
{{toc}}

h1. Title

Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Maecenas sed libero.

h2. Subtitle with a [[Wiki]] link

Nullam commodo metus accumsan nulla. Curabitur lobortis dui id dolor.

h2. Subtitle with [[Wiki|another Wiki]] link

h2. Subtitle with %{color:red}red text%

<pre>
some code
</pre>

h3. Subtitle with *some* _modifiers_

h3. Subtitle with @inline code@

h1. Another title

h3. An "Internet link":http://www.redmine.org/ inside subtitle

h2. "Project Name !/attachments/1234/logo_small.gif! !/attachments/5678/logo_2.png!":/projects/projectname/issues

RAW

    expected =  '<ul class="toc">' +
                  '<li><a href="#Title">Title</a>' +
                    '<ul>' +
                      '<li><a href="#Subtitle-with-a-Wiki-link">Subtitle with a Wiki link</a></li>' +
                      '<li><a href="#Subtitle-with-another-Wiki-link">Subtitle with another Wiki link</a></li>' +
                      '<li><a href="#Subtitle-with-red-text">Subtitle with red text</a>' +
                        '<ul>' +
                          '<li><a href="#Subtitle-with-some-modifiers">Subtitle with some modifiers</a></li>' +
                          '<li><a href="#Subtitle-with-inline-code">Subtitle with inline code</a></li>' +
                        '</ul>' +
                      '</li>' +
                    '</ul>' +
                  '</li>' +
                  '<li><a href="#Another-title">Another title</a>' +
                    '<ul>' +
                      '<li>' +
                        '<ul>' +
                          '<li><a href="#An-Internet-link-inside-subtitle">An Internet link inside subtitle</a></li>' +
                        '</ul>' +
                      '</li>' +
                      '<li><a href="#Project-Name">Project Name</a></li>' +
                    '</ul>' +
                  '</li>' +
               '</ul>'

    @project = Project.find(1)
    assert textilizable(raw).gsub("\n", "").include?(expected)
  end

  def test_table_of_content_should_generate_unique_anchors
    raw = <<-RAW
{{toc}}

h1. Title

h2. Subtitle

h2. Subtitle
RAW

    expected =  '<ul class="toc">' +
                  '<li><a href="#Title">Title</a>' +
                    '<ul>' +
                      '<li><a href="#Subtitle">Subtitle</a></li>' +
                      '<li><a href="#Subtitle-2">Subtitle</a></li>'
                    '</ul>'
                  '</li>' +
               '</ul>'

    @project = Project.find(1)
    result = textilizable(raw).gsub("\n", "")
    assert_include expected, result
    assert_include '<a name="Subtitle">', result
    assert_include '<a name="Subtitle-2">', result
  end

  def test_table_of_content_should_contain_included_page_headings
    raw = <<-RAW
{{toc}}

h1. Included

{{include(Child_1)}}
RAW

    expected = '<ul class="toc">' +
               '<li><a href="#Included">Included</a></li>' +
               '<li><a href="#Child-page-1">Child page 1</a></li>' +
               '</ul>'

    @project = Project.find(1)
    assert textilizable(raw).gsub("\n", "").include?(expected)
  end

  def test_section_edit_links
    raw = <<-RAW
h1. Title

Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Maecenas sed libero.

h2. Subtitle with a [[Wiki]] link

h2. Subtitle with *some* _modifiers_

h2. Subtitle with @inline code@

<pre>
some code

h2. heading inside pre

<h2>html heading inside pre</h2>
</pre>

h2. Subtitle after pre tag
RAW

    @project = Project.find(1)
    set_language_if_valid 'en'
    result = textilizable(raw, :edit_section_links => {:controller => 'wiki', :action => 'edit', :project_id => '1', :id => 'Test'}).gsub("\n", "")

    # heading that contains inline code
    assert_match Regexp.new('<div class="contextual" id="section-4" title="Edit this section">' +
      '<a href="/projects/1/wiki/Test/edit\?section=4"><img alt="Edit" src="/images/edit.png(\?\d+)?" /></a></div>' +
      '<a name="Subtitle-with-inline-code"></a>' +
      '<h2 >Subtitle with <code>inline code</code><a href="#Subtitle-with-inline-code" class="wiki-anchor">&para;</a></h2>'),
      result

    # last heading
    assert_match Regexp.new('<div class="contextual" id="section-5" title="Edit this section">' +
      '<a href="/projects/1/wiki/Test/edit\?section=5"><img alt="Edit" src="/images/edit.png(\?\d+)?" /></a></div>' +
      '<a name="Subtitle-after-pre-tag"></a>' +
      '<h2 >Subtitle after pre tag<a href="#Subtitle-after-pre-tag" class="wiki-anchor">&para;</a></h2>'),
      result
  end

  def test_default_formatter
    with_settings :text_formatting => 'unknown' do
      text = 'a *link*: http://www.example.net/'
      assert_equal '<p>a *link*: <a class="external" href="http://www.example.net/">http://www.example.net/</a></p>', textilizable(text)
    end
  end

  def test_due_date_distance_in_words
    to_test = { Date.today => 'Due in 0 days',
                Date.today + 1 => 'Due in 1 day',
                Date.today + 100 => 'Due in about 3 months',
                Date.today + 20000 => 'Due in over 54 years',
                Date.today - 1 => '1 day late',
                Date.today - 100 => 'about 3 months late',
                Date.today - 20000 => 'over 54 years late',
               }
    ::I18n.locale = :en
    to_test.each do |date, expected|
      assert_equal expected, due_date_distance_in_words(date)
    end
  end

  def test_avatar_enabled
    with_settings :gravatar_enabled => '1' do
      assert avatar(User.find_by_mail('jsmith@somenet.foo')).include?(Digest::MD5.hexdigest('jsmith@somenet.foo'))
      assert avatar('jsmith <jsmith@somenet.foo>').include?(Digest::MD5.hexdigest('jsmith@somenet.foo'))
      # Default size is 50
      assert avatar('jsmith <jsmith@somenet.foo>').include?('size=50')
      assert avatar('jsmith <jsmith@somenet.foo>', :size => 24).include?('size=24')
      # Non-avatar options should be considered html options
      assert avatar('jsmith <jsmith@somenet.foo>', :title => 'John Smith').include?('title="John Smith"')
      # The default class of the img tag should be gravatar
      assert avatar('jsmith <jsmith@somenet.foo>').include?('class="gravatar"')
      assert !avatar('jsmith <jsmith@somenet.foo>', :class => 'picture').include?('class="gravatar"')
      assert_nil avatar('jsmith')
      assert_nil avatar(nil)
    end
  end

  def test_avatar_disabled
    with_settings :gravatar_enabled => '0' do
      assert_equal '', avatar(User.find_by_mail('jsmith@somenet.foo'))
    end
  end

  def test_link_to_user
    user = User.find(2)
    assert_equal '<a href="/users/2" class="user active">John Smith</a>', link_to_user(user)
  end

  def test_link_to_user_should_not_link_to_locked_user
    with_current_user nil do
      user = User.find(5)
      assert user.locked?
      assert_equal 'Dave2 Lopper2', link_to_user(user)
    end
  end

  def test_link_to_user_should_link_to_locked_user_if_current_user_is_admin
    with_current_user User.find(1) do
      user = User.find(5)
      assert user.locked?
      assert_equal '<a href="/users/5" class="user locked">Dave2 Lopper2</a>', link_to_user(user)
    end
  end

  def test_link_to_user_should_not_link_to_anonymous
    user = User.anonymous
    assert user.anonymous?
    t = link_to_user(user)
    assert_equal ::I18n.t(:label_user_anonymous), t
  end

  def test_link_to_attachment
    a = Attachment.find(3)
    assert_equal '<a href="/attachments/3/logo.gif">logo.gif</a>',
      link_to_attachment(a)
    assert_equal '<a href="/attachments/3/logo.gif">Text</a>',
      link_to_attachment(a, :text => 'Text')
    result = link_to("logo.gif", "/attachments/3/logo.gif", :class => "foo")
    assert_equal result,
      link_to_attachment(a, :class => 'foo')
    assert_equal '<a href="/attachments/download/3/logo.gif">logo.gif</a>',
      link_to_attachment(a, :download => true)
    assert_equal '<a href="http://test.host/attachments/3/logo.gif">logo.gif</a>',
      link_to_attachment(a, :only_path => false)
  end

  def test_thumbnail_tag
    a = Attachment.find(3)
    assert_equal '<a href="/attachments/3/logo.gif" title="logo.gif"><img alt="3" src="/attachments/thumbnail/3" /></a>',
      thumbnail_tag(a)
  end

  def test_link_to_project
    project = Project.find(1)
    assert_equal %(<a href="/projects/ecookbook">eCookbook</a>),
                 link_to_project(project)
    assert_equal %(<a href="/projects/ecookbook/settings">eCookbook</a>),
                 link_to_project(project, :action => 'settings')
    assert_equal %(<a href="http://test.host/projects/ecookbook?jump=blah">eCookbook</a>),
                 link_to_project(project, {:only_path => false, :jump => 'blah'})
    result = link_to("eCookbook", "/projects/ecookbook/settings", :class => "project")
    assert_equal result,
                 link_to_project(project, {:action => 'settings'}, :class => "project")
  end

  def test_link_to_project_settings
    project = Project.find(1)
    assert_equal '<a href="/projects/ecookbook/settings">eCookbook</a>', link_to_project_settings(project)

    project.status = Project::STATUS_CLOSED
    assert_equal '<a href="/projects/ecookbook">eCookbook</a>', link_to_project_settings(project)

    project.status = Project::STATUS_ARCHIVED
    assert_equal 'eCookbook', link_to_project_settings(project)
  end

  def test_link_to_legacy_project_with_numerical_identifier_should_use_id
    # numeric identifier are no longer allowed
    Project.where(:id => 1).update_all(:identifier => 25)
    assert_equal '<a href="/projects/1">eCookbook</a>',
                 link_to_project(Project.find(1))
  end

  def test_principals_options_for_select_with_users
    User.current = nil
    users = [User.find(2), User.find(4)]
    assert_equal %(<option value="2">John Smith</option><option value="4">Robert Hill</option>),
      principals_options_for_select(users)
  end

  def test_principals_options_for_select_with_selected
    User.current = nil
    users = [User.find(2), User.find(4)]
    assert_equal %(<option value="2">John Smith</option><option value="4" selected="selected">Robert Hill</option>),
      principals_options_for_select(users, User.find(4))
  end

  def test_principals_options_for_select_with_users_and_groups
    User.current = nil
    users = [User.find(2), Group.find(11), User.find(4), Group.find(10)]
    assert_equal %(<option value="2">John Smith</option><option value="4">Robert Hill</option>) +
      %(<optgroup label="Groups"><option value="10">A Team</option><option value="11">B Team</option></optgroup>),
      principals_options_for_select(users)
  end

  def test_principals_options_for_select_with_empty_collection
    assert_equal '', principals_options_for_select([])
  end

  def test_principals_options_for_select_should_include_me_option_when_current_user_is_in_collection
    users = [User.find(2), User.find(4)]
    User.current = User.find(4)
    assert_include '<option value="4">&lt;&lt; me &gt;&gt;</option>', principals_options_for_select(users)
  end

  def test_stylesheet_link_tag_should_pick_the_default_stylesheet
    assert_match 'href="/stylesheets/styles.css"', stylesheet_link_tag("styles")
  end

  def test_stylesheet_link_tag_for_plugin_should_pick_the_plugin_stylesheet
    assert_match 'href="/plugin_assets/foo/stylesheets/styles.css"', stylesheet_link_tag("styles", :plugin => :foo)
  end

  def test_image_tag_should_pick_the_default_image
    assert_match 'src="/images/image.png"', image_tag("image.png")
  end

  def test_image_tag_should_pick_the_theme_image_if_it_exists
    theme = Redmine::Themes.themes.last
    theme.images << 'image.png'

    with_settings :ui_theme => theme.id do
      assert_match %|src="/themes/#{theme.dir}/images/image.png"|, image_tag("image.png")
      assert_match %|src="/images/other.png"|, image_tag("other.png")
    end
  ensure
    theme.images.delete 'image.png'
  end

  def test_image_tag_sfor_plugin_should_pick_the_plugin_image
    assert_match 'src="/plugin_assets/foo/images/image.png"', image_tag("image.png", :plugin => :foo)
  end

  def test_javascript_include_tag_should_pick_the_default_javascript
    assert_match 'src="/javascripts/scripts.js"', javascript_include_tag("scripts")
  end

  def test_javascript_include_tag_for_plugin_should_pick_the_plugin_javascript
    assert_match 'src="/plugin_assets/foo/javascripts/scripts.js"', javascript_include_tag("scripts", :plugin => :foo)
  end

  def test_raw_json_should_escape_closing_tags
    s = raw_json(["<foo>bar</foo>"])
    assert_equal '["<foo>bar<\/foo>"]', s
  end

  def test_raw_json_should_be_html_safe
    s = raw_json(["foo"])
    assert s.html_safe?
  end

  def test_html_title_should_app_title_if_not_set
    assert_equal 'Redmine', html_title
  end

  def test_html_title_should_join_items
    html_title 'Foo', 'Bar'
    assert_equal 'Foo - Bar - Redmine', html_title
  end

  def test_html_title_should_append_current_project_name
    @project = Project.find(1)
    html_title 'Foo', 'Bar'
    assert_equal 'Foo - Bar - eCookbook - Redmine', html_title
  end

  def test_title_should_return_a_h2_tag
    assert_equal '<h2>Foo</h2>', title('Foo')
  end

  def test_title_should_set_html_title
    title('Foo')
    assert_equal 'Foo - Redmine', html_title
  end

  def test_title_should_turn_arrays_into_links
    assert_equal '<h2><a href="/foo">Foo</a></h2>', title(['Foo', '/foo'])
    assert_equal 'Foo - Redmine', html_title
  end

  def test_title_should_join_items
    assert_equal '<h2>Foo &#187; Bar</h2>', title('Foo', 'Bar')
    assert_equal 'Bar - Foo - Redmine', html_title
  end

  def test_favicon_path
    assert_match %r{^/favicon\.ico}, favicon_path
  end

  def test_favicon_path_with_suburi
    Redmine::Utils.relative_url_root = '/foo'
    assert_match %r{^/foo/favicon\.ico}, favicon_path
  ensure
    Redmine::Utils.relative_url_root = ''
  end

  def test_favicon_url
    assert_match %r{^http://test\.host/favicon\.ico}, favicon_url
  end

  def test_favicon_url_with_suburi
    Redmine::Utils.relative_url_root = '/foo'
    assert_match %r{^http://test\.host/foo/favicon\.ico}, favicon_url
  ensure
    Redmine::Utils.relative_url_root = ''
  end

  def test_truncate_single_line
    str = "01234"
    result = truncate_single_line("#{str}\n#{str}", :length => 10)
    assert_equal "01234 0...", result
    assert !result.html_safe?
    result = truncate_single_line("#{str}<&#>\n#{str}\n#{str}", :length => 15)
    assert_equal "01234<&#> 01...", result
    assert !result.html_safe?
  end

  def test_truncate_single_line_non_ascii
    ja = "\xe6\x97\xa5\xe6\x9c\xac\xe8\xaa\x9e"
    ja.force_encoding('UTF-8') if ja.respond_to?(:force_encoding)
    result = truncate_single_line("#{ja}\n#{ja}\n#{ja}", :length => 10)
    assert_equal "#{ja} #{ja}...", result
    assert !result.html_safe?
  end
end
