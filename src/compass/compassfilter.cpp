/*
 * Copyright (c) 2011 Nokia Corporation.
 */

#include <QDebug>
#include "compassfilter.h"


CompassFilter::CompassFilter()
    : m_ScreenSaver(NULL)
{
}

bool CompassFilter::filter(QCompassReading *reading)
{
    emit azimuthChanged(reading->azimuth(), reading->calibrationLevel());
    return false;
}


void CompassFilter::screenSaverInhibit(const QVariant &inhibit)
{
    if(inhibit.toBool()) {
        qDebug() << "Inhibiting screensaver";
        if(m_ScreenSaver == NULL) {
            m_ScreenSaver = new QSystemScreenSaver;
        }

        m_ScreenSaver->setScreenSaverInhibit();
    }
    else {
        qDebug() << "Removing screensaver inhibiter";
        if(m_ScreenSaver != NULL) {
            delete m_ScreenSaver;
            m_ScreenSaver = NULL;
        }
    }
}
