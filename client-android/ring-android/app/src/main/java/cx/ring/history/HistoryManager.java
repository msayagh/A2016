/*
 *  Copyright (C) 2004-2016 Savoir-faire Linux Inc.
 *
 *  Author: Alexandre Lision <alexandre.lision@savoirfairelinux.com>
 *  Author: Adrien Béraud <adrien.beraud@savoirfairelinux.com>
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *   Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 */

package cx.ring.history;

import android.content.ContentValues;
import android.content.Context;
import android.content.SharedPreferences;
import android.preference.PreferenceManager;
import android.provider.CallLog;
import android.util.Log;

import com.j256.ormlite.android.apptools.OpenHelperManager;
import com.j256.ormlite.stmt.QueryBuilder;
import com.j256.ormlite.table.TableUtils;

import cx.ring.R;
import cx.ring.fragments.SettingsFragment;
import cx.ring.model.Conference;
import cx.ring.model.SipCall;
import cx.ring.model.TextMessage;

import java.sql.SQLException;
import java.util.List;

public class HistoryManager {
    private static final String TAG = HistoryManager.class.getSimpleName();

    private Context mContext;
    private DatabaseHelper historyDBHelper = null;

    public HistoryManager(Context context) {
        mContext = context;
        getHelper();
    }

    public boolean insertNewEntry(Conference toInsert){
        SharedPreferences sharedPref = PreferenceManager.getDefaultSharedPreferences(mContext);
        boolean val = sharedPref.getBoolean(mContext.getString(R.string.pref_systemDialer_key), false);

        for (SipCall call : toInsert.getParticipants()) {
            call.setTimestampEnd(System.currentTimeMillis());
            if (val) {
                try {
                    ContentValues values = new ContentValues();
                    values.put(CallLog.Calls.NUMBER, call.getNumber());
                    values.put(CallLog.Calls.DATE, call.getTimestampStart());
                    values.put(CallLog.Calls.DURATION, call.getDuration());
                    values.put(CallLog.Calls.TYPE, call.isMissed() ? CallLog.Calls.MISSED_TYPE : (call.isIncoming() ? CallLog.Calls.INCOMING_TYPE : CallLog.Calls.OUTGOING_TYPE));
                    values.put(CallLog.Calls.NEW, 1);
                    values.put(CallLog.Calls.CACHED_NAME, call.getContact().getDisplayName());
                    values.put(CallLog.Calls.CACHED_NUMBER_TYPE, 0);
                    values.put(CallLog.Calls.CACHED_NUMBER_LABEL, "");
                    mContext.getContentResolver().insert(CallLog.Calls.CONTENT_URI, values);
                } catch (SecurityException e) {
                    Log.e(TAG, "Can't insert call in call log: ", e);
                }
            }

            HistoryCall persistent = new HistoryCall(call);
            try {
                Log.w("HistoryManager", "HistoryDao().create() " + persistent.getNumber() + " " + persistent.getStartDate().toString() + " " + persistent.getEndDate());
                getHelper().getHistoryDao().create(persistent);
            } catch (SQLException e) {
                e.printStackTrace();
                return false;
            }
        }
        return true;
    }

    public boolean insertNewTextMessage(HistoryText txt) {
        try {
            Log.w("HistoryManager", "HistoryDao().create() acc:" + txt.getAccountID() + " num:" + txt.getNumber() + " date:" + txt.getDate().toString() + " msg:" + txt.getMessage());
            getHelper().getTextHistoryDao().create(txt);
        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
        return true;
    }

    public boolean insertNewTextMessage(TextMessage txt) {
        HistoryText htxt = new HistoryText(txt);
        if (!insertNewTextMessage(htxt))
            return false;
        txt.setID(htxt.id);
        return true;
    }

    public boolean updateTextMessage(HistoryText txt) {
        try {
            Log.w("HistoryManager", "HistoryDao().update() id:"+txt.id+" acc:" + txt.getAccountID() + " num:" + txt.getNumber() + " date:" + txt.getDate().toString() + " msg:" + txt.getMessage());
            getHelper().getTextHistoryDao().update(txt);
        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
        return true;
    }

    /*
    * Necessary when user hang up a call in a Conference
    * The call creates an HistoryCall, but the conference still goes on
    */
    public boolean insertNewEntry(SipCall toInsert){
        return true;
    }

    /**
     * Retrieve helper for our DB
     */
    private DatabaseHelper getHelper() {
        if (historyDBHelper == null) {
            historyDBHelper = OpenHelperManager.getHelper(mContext, DatabaseHelper.class);
        }
        return historyDBHelper;
    }

    public List<HistoryCall> getAll() throws SQLException {
        QueryBuilder<HistoryCall, Integer> qb = getHelper().getHistoryDao().queryBuilder();
        qb.orderBy("TIMESTAMP_START", true);
        return getHelper().getHistoryDao().query(qb.prepare());
    }

    public List<HistoryText> getAllTextMessages() throws SQLException {
        QueryBuilder<HistoryText, Integer> qb = getHelper().getTextHistoryDao().queryBuilder();
        qb.orderBy("TIMESTAMP", true);
        return getHelper().getTextHistoryDao().query(qb.prepare());
    }

    public boolean clearDB() {
        try {
            TableUtils.clearTable(getHelper().getConnectionSource(), HistoryCall.class);
            TableUtils.clearTable(getHelper().getConnectionSource(), HistoryText.class);
        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
        return true;
    }
}
