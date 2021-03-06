
////////////////////////////////////////////////////////////////////////////
//
// RTP processing
//
////////////////////////////////////////////////////////////////////////////

#ifndef CYBERMON_RTP_H
#define CYBERMON_RTP_H

#include <cybermon/context.h>
#include <cybermon/manager.h>
#include <cybermon/pdu.h>


namespace cybermon
{
    
class rtp
{
  public:

    static void process(manager& mgr, context_ptr c, pdu_iter s, pdu_iter e);
};

}; // End namespace

#endif

