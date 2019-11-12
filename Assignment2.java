import java.sql.*;
// You should use this class so that you can represent SQL points as
// Java PGpoint objects.
import org.postgresql.geometric.PGpoint;

public class Assignment2 {

    // A connection to the database
    Connection connection;

    Assignment2() throws SQLException {
        try {
            Class.forName("org.postgresql.Driver");
        } catch (ClassNotFoundException e) {
            e.printStackTrace();
        }
    }

    /**
     * Connects and sets the search path.
     *
     * Establishes a connection to be used for this session, assigning it to
     * the instance variable 'connection'.  In addition, sets the search
     * path to uber, public.
     *
     * @param  url       the url for the database
     * @param  username  the username to connect to the database
     * @param  password  the password to connect to the database
     * @return           true if connecting is successful, false otherwise
     */
    public boolean connectDB(String URL, String username, String password) {
        // Implement this method!
        try {
            connection = DriverManager.getConnection(URL, username, password);
            PreparedStatement init;
            init = connection.prepareStatement("SET SEARCH_PATH TO uber, "
                    + "public");
            init.execute();
        } catch(SQLException se){
            return false;
        }
        return true;
    }

    /**
     * Closes the database connection.
     *
     * @return true if the closing was successful, false otherwise
     */
    public boolean disconnectDB() {
        // Implement this method!
        try {
            connection.close();
        } catch(SQLException se){
            return false;
        }
        return true;
    }

    /* ======================= Driver-related methods ====================== */

    /**
     * Records the fact that a driver has declared that he or she is available
     * to pick up a client.
     *
     * Does so by inserting a row into the Available table.
     *
     * @param  driverID  id of the driver
     * @param  when      the date and time when the driver became available
     * @param  location  the coordinates of the driver at the time when
     *                   the driver became available
     * @return           true if the insertion was successful, false otherwise.
     */
    public boolean available(int driverID, Timestamp when, PGpoint location) {
        // Implement this method!
        try {
            PreparedStatement execAdd = connection.prepareStatement("INSERT "
                    + "INTO Available VALUES (?, ?, ?)");
            execAdd.setInt(1, driverID);
            execAdd.setTimestamp(2, when);
            execAdd.setObject(3, location);
            execAdd.executeUpdate();
        } catch(SQLException se){
            return false;
        }
        return true;
    }

    /**
     * Records the fact that a driver has picked up a client.
     *
     * If the driver was dispatched to pick up the client and the corresponding
     * pick-up has not been recorded, records it by adding a row to the
     * Pickup table, and returns true.  Otherwise, returns false.
     *
     * @param  driverID  id of the driver
     * @param  clientID  id of the client
     * @param  when      the date and time when the pick-up occurred
     * @return           true if the operation was successful, false otherwise
     */
    public boolean picked_up(int driverID, int clientID, Timestamp when) {
        // Implement this method!
        try {
            PreparedStatement execPick;
            ResultSet rs;
            String queryString;
            execPick = connection.prepareStatement("select "
                    + "Dispatch.request_id, "
                    + "Dispatch.driver_id, Request.client_id from Dispatch, "
                    + "Request where Dispatch.request_id = Request.request_id "
                    + "and not exists (select p.request_id from Pickup p "
                    + "where Dispatch.request_id = p.request_id)");
            // execPick.setString(1, String.valueOf(driverID));
            rs = execPick.executeQuery();
            while(rs.next()){
                int request = rs.getInt("request_id");
                int driver = rs.getInt("driver_id");
                int client = rs.getInt("client_id");
                if(driverID == driver){
                    execPick = connection.prepareStatement("INSERT "
                            + "INTO Pickup VALUES (?, ?)");
                    execPick.setInt(1, request);
                    execPick.setTimestamp(2, when);
                    execPick.executeUpdate();
                }
            }
        } catch(SQLException se){
            return false;
        }
        return true;
    }
    /* ===================== Dispatcher-related methods ==================== */

    /**
     * Dispatches drivers to the clients who've requested rides in the area
     * bounded by NW and SE.
     *
     * For all clients who have requested rides in this area (i.e., whose
     * request has a source location in this area), dispatches drivers to them
     * one at a time, from the client with the highest total billings down
     * to the client with the lowest total billings, or until there are no
     * more drivers available.
     *
     * Only drivers who (a) have declared that they are available and have
     * not since then been dispatched, and (b) whose location is in the area
     * bounded by NW and SE, are dispatched.  If there are several to choose
     * from, the one closest to the client's source location is chosen.
     * In the case of ties, any one of the tied drivers may be dispatched.
     *
     * Area boundaries are inclusive.  For example, the point (4.0, 10.0)
     * is considered within the area defined by
     *         NW = (1.0, 10.0) and SE = (25.0, 2.0)
     * even though it is right at the upper boundary of the area.
     *
     * Dispatching a driver is accomplished by adding a row to the
     * Dispatch table.  All dispatching that results from a call to this
     * method is recorded to have happened at the same time, which is
     * passed through parameter 'when'.
     *
     * @param  NW    x, y coordinates in the northwest corner of this area.
     * @param  SE    x, y coordinates in the southeast corner of this area.
     * @param  when  the date and time when the dispatching occurred
     */
    public void dispatch(PGpoint NW, PGpoint SE, Timestamp when) {
        // Implement this method!
        try {
            PreparedStatement dropView1 = connection.prepareStatement("DROP "
                    + "VIEW IF EXISTS allBills cascade");
            PreparedStatement dropView2 = connection.prepareStatement("DROP "
                    + "VIEW IF EXISTS ordered cascade");
            PreparedStatement dropView3 = connection.prepareStatement("DROP "
                    + "VIEW IF EXISTS latestAvail cascade");
            PreparedStatement dropView4 = connection.prepareStatement("DROP "
                    + "VIEW IF EXISTS availTime cascade");
            dropView1.execute();
            dropView2.execute();
            dropView3.execute();
            dropView4.execute();
        } catch (SQLException se) {
            System.err.println("SQL Exception when dropping views." +
                    "<Message>: " + se.getMessage());
        }
        try {
            PreparedStatement getBills = connection.prepareStatement("create "
                    + "view allBills as "
                    + "select Request.client_id, sum(Billed.amount) as amount "
                    + "from Request join Billed "
                    + "on Request.request_id = Billed.request_id "
                    + "group by Request.client_id");
            getBills.execute();
        } catch (SQLException se) {
            System.err.println("SQL Exception when getting all bills." +
                    "<Message>: " + se.getMessage());
        }

        try {
            PreparedStatement getOrder = connection.prepareStatement("create "
                    + "view ordered as "
                    + "select request_id, Request.client_id, datetime, "
                    + "location as source, amount "
                    + "from Request join allBills "
                    + "on Request.client_id = allBills.client_id "
                    + "join Place on source = name "
                    + "order by amount DESC");
            getOrder.execute();
        } catch (SQLException se) {
            System.err.println("SQL Exception when getting ordered clients." +
                    "<Message>: " + se.getMessage());
        }

        try {
            PreparedStatement availTime = connection.prepareStatement("create "
                    + "view availTime as "
                    + "select driver_id, "
                    + "max(datetime) as datetime from Available group by "
                    + "driver_id");
            availTime.execute();
        } catch (SQLException se){
            System.err.println("SQL Exception when getting available time." +
                    "<Message>: " + se.getMessage());
        }

        try {
            PreparedStatement getLatestAvail = connection.prepareStatement(""
                    + "create view latestAvail as "
                    + "select Available.driver_id, Available.datetime, "
                    + "location "
                    + "from Available join availTime "
                    + "on Available.driver_id = availTime.driver_id "
                    + "and Available.datetime = availTime.datetime");
            getLatestAvail.execute();
        } catch (SQLException se){
            System.err.println("SQL Exception when getting latest " +
                    "available time.<Message>: " + se.getMessage());
        }

        try {
            PreparedStatement getClients = connection.prepareStatement(""
                    + "select request_id, "
                    + "client_id, datetime, source from ordered "
                    + "where source[0] >= ? and source[0] <= ? "
                    + "and source[1] >= ? and source[1] <= ? "
                    + "and not exists (select request_id from Dispatch "
                    + "where Dispatch.request_id = ordered.request_id)");
            getClients.setDouble(1, NW.x);
            getClients.setDouble(2, SE.x);
            getClients.setDouble(3, SE.y);
            getClients.setDouble(4, NW.y);
            ResultSet rs = getClients.executeQuery();
            while(rs.next()){
                try {
                    PreparedStatement dropView5 =
                            connection.prepareStatement("DROP VIEW "
                            + "IF EXISTS goodDrivers cascade");
                    dropView5.execute();
                } catch (SQLException se) {
                    System.err.println("SQL Exception when dropping views." +
                            "<Message>: " + se.getMessage());
                }

                try {
                    PreparedStatement getDrivers;
                    getDrivers = connection.prepareStatement("create view "
                            + "goodDrivers as "
                            + "select latestAvail.driver_id, "
                            + "latestAvail.location "
                            + "from latestAvail "
                            + "where not exists "
                            + "(select latestAvail.driver_id, "
                            + "latestAvail.datetime "
                            + "from latestAvail join Dispatch "
                            + "on latestAvail.driver_id = Dispatch.driver_id "
                            + "where Dispatch.datetime > "
                            + "latestAvail.datetime)");
                    getDrivers.execute();
                } catch (SQLException se){
                    System.err.println("SQL Exception when getting latest " +
                            "available time.<Message>: " + se.getMessage());
                }

                try {
                    PreparedStatement bestDriver;
                    bestDriver = connection.prepareStatement("select "
                            + "driver_id, location, "
                            + "? <@> location as distance "
                            + "from goodDrivers "
                            + "where location[0] >= ? and location[0] <= ? "
                            + "and location[1] >= ? "
                            + "and location[1] <= ? "
                            + "order by distance limit 1");
                    bestDriver.setObject(1, (PGpoint) rs.getObject("source"));
                    bestDriver.setDouble(2, NW.x);
                    bestDriver.setDouble(3, SE.x);
                    bestDriver.setDouble(4, SE.y);
                    bestDriver.setDouble(5, NW.y);
                    ResultSet toDispatch = bestDriver.executeQuery();
                    if (toDispatch.next()){
                        int request_id = rs.getInt("request_id");
                        int driver_id = toDispatch.getInt("driver_Id");
                        PGpoint car_location =
                                (PGpoint) toDispatch.getObject("location");
                        try {
                            PreparedStatement insert;
                            insert = connection.prepareStatement("insert into "
                                    + "Dispatch values (?, ?, ?, ?)");
                            insert.setInt(1, request_id);
                            insert.setInt(2, driver_id);
                            insert.setObject(3, car_location);
                            insert.setTimestamp(4, when);
                            insert.execute();
                        } catch (SQLException se){
                            System.err.println("SQL Exception when inserting "
                                    + "to dispatch." +
                                    "<Message>: " + se.getMessage());
                        }
                    } else {break;}
                } catch (SQLException se){
                    System.err.println("SQL Exception when getting best " +
                            "driver.<Message>: " + se.getMessage());
                }
            }
        } catch (SQLException se) {
            System.err.println("SQL Exception when getting clients." +
                    "<Message>: " + se.getMessage());
        }

    }

    public static void main(String[] args) {
        // You can put testing code in here. It will not affect our autotester.
        try{
            Assignment2 a2 = new Assignment2();
            String url = "jdbc:postgresql://localhost:5432/csc343h-chengj60";
            String user = "chengj60";
            System.out.println("connection succeed: "
                    + a2.connectDB(url, user, ""));
            //a2.printResult();
            Timestamp t = new Timestamp(System.currentTimeMillis());;
            PGpoint p1 = new PGpoint(0, 100);
            System.out.println("x: " + p1.x + "y: " + p1.y);
            System.out.println("available pass: "
                    + a2.available(12345, t, p1));
            System.out.println("pickup pass: " + a2.picked_up(12345, 1, t));
            //a2.printResult();
            PGpoint p2 = new PGpoint(100, 0);
            System.out.println("dispatch pass: ?");
            a2.dispatch(p1, p2, t);
            //a2.printResult();
            a2.disconnectDB();
            //System.out.println("Now the connection is closed, " +
            //        "the following result should raise error!");
            //a2.printResult();
        } catch (Exception e){
            System.out.println("Boo!");
        }
    }

}
