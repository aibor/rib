# coding = UTF-8

#$LOAD_PATH.unshift File.expand_path('../mock', __FILE__)

require 'minitest/autorun'
require 'minitest/pride'
require 'rib/adapters/irc'
require 'socket'

old_verbose = $VERBOSE
$VERBOSE = nil
#RIB::Adapters::IRC::Connection.const_set(:PING_INTERVAL, 0.2)
$VERBOSE = old_verbose


class TestIRCConnection < MiniTest::Test

 # parallelize_me!
  make_my_diffs_pretty!


  def setup
    old_verbose = $VERBOSE
    $VERBOSE = nil
    #RIB::Adapters::IRC::Connection.const_set(:PING_INTERVAL, 0)
    $VERBOSE = old_verbose
  end


  def test_construct
    conn, tcpsocket = get_connection
    assert_instance_of(RIB::Adapters::IRC::Connection, conn)
    assert_equal tcpsocket.to_s, conn.instance_variable_get(:@irc_socket).to_s
  end


  def test_receive_privmsg
    conn, tcpsocket = get_connection
    tcpsocket.expect(
      :gets,
      ":rib!~rib@rib.users.example.org PRIVMSG #rib :Moin!\r\n"
    )
    cmd = conn.receive
    refute_nil(cmd)
    assert_instance_of(RIB::Adapters::IRC::Message, cmd)
    assert_equal("#rib", cmd.source)
    assert_equal("rib!~rib@rib.users.example.org", cmd.prefix)
    assert_equal("PRIVMSG", cmd.command)
    assert_equal( ["#rib", "Moin!"],
                 cmd.params )
    assert_equal( "Moin!",
                  cmd.data )
    assert tcpsocket.verify
  end


  def test_receive_arbitrary_command
    conn, tcpsocket = get_connection
    tcpsocket.expect(:gets, "TIME")
    cmd = conn.receive
    refute_nil(cmd)
    assert_instance_of(RIB::Adapters::IRC::Message, cmd)
    assert_nil(cmd.prefix)
    assert_equal("TIME", cmd.command)
    assert_equal([], cmd.params)
    assert_nil(cmd.data)
    assert tcpsocket.verify
  end


  def test_receive_error
    conn, tcpsocket = get_connection
    tcpsocket.expect(:gets, "ERROR :karpoooot\r\n")

    assert_raises(RIB::ReceivedError) { conn.receive }
    assert tcpsocket.verify
  end


  def test_receive_ctcp
    conn, tcpsocket = get_connection
    tcpsocket.expect(
      :gets, 
      ":rib!~rib@localhost PRIVMSG #rib :PING 1234\r\n"
    )
    tcpsocket.expect(:print, nil, ["NOTICE #rib :PING 1234\r\n"])

    conn.receive
    assert tcpsocket.verify
  end


  def test_receive_instant_action
    conn, tcpsocket = get_connection
    tcpsocket.expect(:gets, "PING 1234\r\n")
    tcpsocket.expect(:print, nil, ["PONG 1234\r\n"])
    tcpsocket.expect(:gets, "yo 1234\r\n")

    conn.receive
    assert tcpsocket.verify
  end


  def test_ping_loop
    conn, tcpsocket = get_connection
    tcpsocket.expect(:print, nil, ["PING 1\r\n"])
    tcpsocket.expect(:gets, "PONG 1\r\n")
    tcpsocket.expect(:gets, "yo 1\r\n")
    conn.send(:start_ping_thread)
    sleep 0.1
    conn.stop_ping_thread rescue nil
    conn.receive
    assert_equal "1", conn.instance_variable_get(:@last_pong)
    assert tcpsocket.verify
  end

  def test_ping_loop_lost_connection
    conn, tcpsocket = get_connection
    tcpsocket.expect(:print, nil, ["PING 1\r\n"])
    tcpsocket.expect(:gets, "PONG 5\r\n")
    tcpsocket.expect(:gets, "yo 5\r\n")
    conn.receive
    assert_equal "5", conn.instance_variable_get(:@last_pong)
    assert_raises(RIB::LostConnectionError) {
      conn.send(:start_ping_thread)
      thread = conn.instance_variable_get(:@ping_thread)
      thread.join
      thread.value
    }
  end
    

  def test_login
    conn, tcpsocket = get_connection
    tcpsocket.expect(:print, nil, ["NICK rib\r\n"])
    tcpsocket.expect(:print, nil, ["USER rib rib.rules.org rib.rules.org :rib\r\n"])
    tcpsocket.expect(:gets, ":localhost 001\r\n")

    assert_nil conn.login
    conn.stop_ping_thread
    assert tcpsocket.verify
  end


  def test_login_raises_on_error
    conn, tcpsocket = get_connection
    tcpsocket.expect(:print, nil, ["NICK rib\r\n"])
    tcpsocket.expect(:print, nil, ["USER rib rib.rules.org rib.rules.org :rib\r\n"])
    tcpsocket.expect(:gets, ":localhost 462\r\n")

    assert_raises(RIB::LoginError) { conn.login }
    assert tcpsocket.verify
  end


  def test_authdata
    conn, tcpsocket = get_connection
    tcpsocket.expect(:print, nil, ["PRIVMSG nickserv :identify 12345\r\n"])
    tcpsocket.expect(:print, nil, ["MODE rib +x  \r\n"])
    res = conn.auth_nick('nickserv identify 12345')
    assert_equal('auth sent', res)
  end


  def test_authdata_raises_without_authdata
    conn = get_connection.first
    assert_raises(RIB::AuthError) { conn.auth_nick(nil) }
  end


  def test_join_channel
    conn, tcpsocket = get_connection
    log_mock = MiniTest::Mock.new
    conn.instance_variable_set(:@logging, log_mock)
    log_mock.expect(:server, nil)
    log_mock.expect(:server, nil)
    log_mock.expect(:add_channel_log, true, ['#test'])
    tcpsocket.expect(:print, nil, ["JOIN #test\r\n"])
    tcpsocket.expect(:gets, ":localhost 332\r\n")

    assert conn.join_channel('#test')
    assert tcpsocket.verify
    assert log_mock.verify
  end


  def test_join_channel_raises_on_error
    conn, tcpsocket = get_connection
    tcpsocket.expect(:print, nil, ["JOIN #test\r\n"])
    tcpsocket.expect(:gets, ":localhost 461\r\n")

    assert_raises(RIB::ChannelJoinError) { conn.join_channel('#test') }
    assert tcpsocket.verify
  end


  def test_whois
    conn, tcpsocket = get_connection
    prepare_mock_for_whois(tcpsocket)

    user = conn.whois('rib')

    assert_instance_of(RIB::Adapters::IRC::Connection::User, user)
    assert_equal('~rib 127.0.0.1 rib', user.user)
    assert_equal(['#test'], user.channels)
    assert_equal('localhost localhost', user.server)
    assert_equal('rib', user.auth)
    assert tcpsocket.verify
  end


  def test_setme
    conn, tcpsocket = get_connection
    conn, tcpsocket = get_connection
    prepare_mock_for_whois(tcpsocket)

    assert_equal(':rib!~rib@127.0.0.1 ', conn.setme('rib'))
    assert tcpsocket.verify
  end


  private

  def prepare_mock_for_whois(tcpsocket)
    tcpsocket.expect(:print, nil, ["WHOIS rib\r\n"])
    tcpsocket.expect(:gets, ":localhost 311 rib rib ~rib 127.0.0.1 :rib\r\n")
    tcpsocket.expect(:gets, ":localhost 319 rib rib :#test\r\n")
    tcpsocket.expect(:gets, ":localhost 312 rib rib localhost :localhost\r\n")
    tcpsocket.expect(:gets, ":localhost 330 rib rib rib :is authed as\r\n")
    tcpsocket.expect(:gets, ":localhost 318 rib rib :End of /WHOIS list.\r\n")
  end


  def get_connection
    tcpsocket = Minitest::Mock.new
    conn = TCPSocket.stub :new, tcpsocket do
      RIB::Adapters::IRC::Connection.new(
        "irc.example.org",
        "rib",
        "/tmp/",
      )
    end
    [conn, tcpsocket]
  end

end
