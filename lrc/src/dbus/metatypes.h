/******************************************************************************
 *   Copyright (C) 2009-2016 by Savoir-faire Linux                                 *
 *   Author : Emmanuel Lepage Vallee <emmanuel.lepage@savoirfairelinux.com>   *
 *            Jérémy Quentin <jeremy.quentin@savoirfairelinux.com>            *
 *                                                                            *
 *   This library is free software; you can redistribute it and/or            *
 *   modify it under the terms of the GNU Lesser General Public               *
 *   License as published by the Free Software Foundation; either             *
 *   version 2.1 of the License, or (at your option) any later version.       *
 *                                                                            *
 *   This library is distributed in the hope that it will be useful,          *
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of           *
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU        *
 *   Lesser General Public License for more details.                          *
 *                                                                            *
 *   You should have received a copy of the Lesser GNU General Public License *
 *   along with this program.  If not, see <http://www.gnu.org/licenses/>.    *
 *****************************************************************************/
#pragma once

#include <QtCore/QMetaType>
#include <QtCore/QMap>
#include <QtCore/QVector>
#include <QtCore/QString>

#include "../typedefs.h"

#ifndef ENABLE_LIBWRAP
#include <QtDBus/QtDBus>
#endif
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wzero-as-null-pointer-constant"

Q_DECLARE_METATYPE(MapStringString)
Q_DECLARE_METATYPE(MapStringInt)
Q_DECLARE_METATYPE(VectorMapStringString)
Q_DECLARE_METATYPE(MapStringMapStringStringList)
Q_DECLARE_METATYPE(VectorInt)
Q_DECLARE_METATYPE(VectorUInt)
Q_DECLARE_METATYPE(VectorString)
Q_DECLARE_METATYPE(MapStringVectorString)
Q_DECLARE_METATYPE(VectorVectorByte)

#ifndef ENABLE_LIBWRAP
static bool dbus_metaTypeInit = false;
#endif
inline void registerCommTypes() {
#ifndef ENABLE_LIBWRAP
   qDBusRegisterMetaType<MapStringString>               ();
   qDBusRegisterMetaType<MapStringInt>                  ();
   qDBusRegisterMetaType<VectorMapStringString>         ();
   qDBusRegisterMetaType<MapStringMapStringVectorString>();
   qDBusRegisterMetaType<VectorInt>                     ();
   qDBusRegisterMetaType<VectorUInt>                    ();
   qDBusRegisterMetaType<VectorString>                  ();
   qDBusRegisterMetaType<MapStringVectorString>         ();
   qDBusRegisterMetaType<VectorVectorByte>              ();
   dbus_metaTypeInit = true;
#endif
}


#pragma GCC diagnostic pop
